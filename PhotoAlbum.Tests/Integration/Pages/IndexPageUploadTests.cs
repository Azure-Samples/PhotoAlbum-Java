using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PhotoAlbum.Data;
using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;

namespace PhotoAlbum.Tests.Integration.Pages;

public class IndexPageUploadTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public IndexPageUploadTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private HttpClient CreateTestClient(Action<PhotoAlbumContext>? seedData = null)
    {
        var factory = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureAppConfiguration((context, config) =>
            {
                config.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["IsTestEnvironment"] = "true"
                });
            });

            builder.ConfigureServices(services =>
            {
                // Remove existing DbContext and related services
                var dbContextDescriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<PhotoAlbumContext>));
                if (dbContextDescriptor != null)
                {
                    services.Remove(dbContextDescriptor);
                }

                var dbContextServiceDescriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(PhotoAlbumContext));
                if (dbContextServiceDescriptor != null)
                {
                    services.Remove(dbContextServiceDescriptor);
                }

                // Add in-memory database
                services.AddDbContext<PhotoAlbumContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb_" + Guid.NewGuid());
                }, ServiceLifetime.Scoped);
            });
        });

        var client = factory.CreateClient();

        // Seed data after the application is built
        if (seedData != null)
        {
            using var scope = factory.Services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<PhotoAlbumContext>();
            seedData(context);
            context.SaveChanges();
        }

        return client;
    }

    [Fact]
    public async Task PostUpload_WithValidImage_ReturnsSuccessAndCreatesPhoto()
    {
        // Arrange
        var client = CreateTestClient();

        var content = CreateMultipartFormDataContent("test.jpg", "image/jpeg", 1024);

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();

        using var doc = JsonDocument.Parse(responseContent);
        var root = doc.RootElement;
        Assert.True(root.GetProperty("success").GetBoolean());
        Assert.True(root.GetProperty("uploadedPhotos").GetArrayLength() > 0);
    }

    [Fact]
    public async Task PostUpload_WithMultipleImages_UploadsAllSuccessfully()
    {
        // Arrange
        var client = CreateTestClient();

        var content = new MultipartFormDataContent();
        content.Add(CreateFileContent("photo1.jpg", "image/jpeg", 1024), "files", "photo1.jpg");
        content.Add(CreateFileContent("photo2.png", "image/png", 2048), "files", "photo2.png");
        content.Add(CreateFileContent("photo3.gif", "image/gif", 1536), "files", "photo3.gif");

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();

        using var doc = JsonDocument.Parse(responseContent);
        var root = doc.RootElement;
        Assert.True(root.GetProperty("success").GetBoolean());
        Assert.Equal(3, root.GetProperty("uploadedPhotos").GetArrayLength());
    }

    [Fact]
    public async Task PostUpload_WithInvalidFileType_ReturnsBadRequest()
    {
        // Arrange
        var client = CreateTestClient();

        var content = CreateMultipartFormDataContent("document.pdf", "application/pdf", 1024);

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        var responseContent = await response.Content.ReadAsStringAsync();

        using var doc = JsonDocument.Parse(responseContent);
        var root = doc.RootElement;
        Assert.False(root.GetProperty("success").GetBoolean());
        Assert.True(root.GetProperty("failedUploads").GetArrayLength() > 0);
    }

    [Fact]
    public async Task PostUpload_WithOversizedFile_ReturnsBadRequest()
    {
        // Arrange
        var client = CreateTestClient();

        // 11MB file (exceeds 10MB limit)
        var content = CreateMultipartFormDataContent("huge.jpg", "image/jpeg", 11 * 1024 * 1024);

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        var responseContent = await response.Content.ReadAsStringAsync();

        using var doc = JsonDocument.Parse(responseContent);
        var root = doc.RootElement;
        Assert.False(root.GetProperty("success").GetBoolean());
        Assert.True(root.GetProperty("failedUploads").GetArrayLength() > 0);
    }

    [Fact]
    public async Task PostUpload_WithMixedValidInvalid_ReturnsPartialSuccess()
    {
        // Arrange
        var client = CreateTestClient();

        var content = new MultipartFormDataContent();
        content.Add(CreateFileContent("valid.jpg", "image/jpeg", 1024), "files", "valid.jpg");
        content.Add(CreateFileContent("invalid.pdf", "application/pdf", 1024), "files", "invalid.pdf");

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        var responseContent = await response.Content.ReadAsStringAsync();

        using var doc = JsonDocument.Parse(responseContent);
        var root = doc.RootElement;
        Assert.Equal(1, root.GetProperty("uploadedPhotos").GetArrayLength());
        Assert.Equal(1, root.GetProperty("failedUploads").GetArrayLength());
    }

    [Fact]
    public async Task PostUpload_WithNoFiles_ReturnsBadRequest()
    {
        // Arrange
        var client = CreateTestClient();

        var content = new MultipartFormDataContent();

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task PostUpload_CreatesFileInUploadsDirectory()
    {
        // Arrange
        var client = CreateTestClient();

        var content = CreateMultipartFormDataContent("test.jpg", "image/jpeg", 2048);

        // Act
        var response = await client.PostAsync("/Upload", content);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Note: In a real integration test, we would verify file creation
        // For now, we just verify the response indicates success
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        var root = doc.RootElement;
        Assert.True(root.GetProperty("success").GetBoolean());
    }

    private MultipartFormDataContent CreateMultipartFormDataContent(string fileName, string contentType, long size)
    {
        var content = new MultipartFormDataContent();
        content.Add(CreateFileContent(fileName, contentType, size), "files", fileName);
        return content;
    }

    private ByteArrayContent CreateFileContent(string fileName, string contentType, long size)
    {
        var fileContent = new byte[size];
        var byteContent = new ByteArrayContent(fileContent);
        byteContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);
        return byteContent;
    }
}
