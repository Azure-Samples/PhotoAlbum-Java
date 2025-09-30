using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PhotoAlbum.Data;
using PhotoAlbum.Models;
using System.Net;

namespace PhotoAlbum.Tests.Integration.Pages;

public class IndexPageGetTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public IndexPageGetTests(WebApplicationFactory<Program> factory)
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
    public async Task GetIndex_WithNoPhotos_ReturnsEmptyGallery()
    {
        // Arrange
        var client = CreateTestClient();

        // Act
        var response = await client.GetAsync("/");

        // Assert
        response.EnsureSuccessStatusCode();
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("No photos yet", content);
    }

    [Fact]
    public async Task GetIndex_WithPhotos_ReturnsGalleryWithPhotos()
    {
        // Arrange
        var client = CreateTestClient(context =>
        {
            context.Photos.Add(new Photo
            {
                OriginalFileName = "test1.jpg",
                StoredFileName = "guid1.jpg",
                FilePath = "/uploads/guid1.jpg",
                FileSize = 1024,
                MimeType = "image/jpeg",
                UploadedAt = DateTime.UtcNow
            });
        });

        // Act
        var response = await client.GetAsync("/");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("test1.jpg", content);
        Assert.Contains("/uploads/guid1.jpg", content);
    }

    [Fact]
    public async Task GetIndex_WithManyPhotos_ReturnsPhotosInChronologicalOrder()
    {
        // Arrange
        var client = CreateTestClient(context =>
        {
            context.Photos.AddRange(
                new Photo
                {
                    OriginalFileName = "oldest.jpg",
                    StoredFileName = "guid1.jpg",
                    FilePath = "/uploads/guid1.jpg",
                    FileSize = 1024,
                    MimeType = "image/jpeg",
                    UploadedAt = DateTime.UtcNow.AddHours(-2)
                },
                new Photo
                {
                    OriginalFileName = "middle.jpg",
                    StoredFileName = "guid2.jpg",
                    FilePath = "/uploads/guid2.jpg",
                    FileSize = 2048,
                    MimeType = "image/jpeg",
                    UploadedAt = DateTime.UtcNow.AddHours(-1)
                },
                new Photo
                {
                    OriginalFileName = "newest.jpg",
                    StoredFileName = "guid3.jpg",
                    FilePath = "/uploads/guid3.jpg",
                    FileSize = 3072,
                    MimeType = "image/jpeg",
                    UploadedAt = DateTime.UtcNow
                }
            );
        });

        // Act
        var response = await client.GetAsync("/");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();

        // Verify newest appears before oldest in the HTML
        var newestIndex = content.IndexOf("newest.jpg", StringComparison.Ordinal);
        var oldestIndex = content.IndexOf("oldest.jpg", StringComparison.Ordinal);
        Assert.True(newestIndex < oldestIndex, "Newest photo should appear before oldest photo");
    }
}
