using Microsoft.EntityFrameworkCore;
using PhotoAlbum.Models;

namespace PhotoAlbum.Data;

/// <summary>
/// Database context for the Photo Album application
/// </summary>
public class PhotoAlbumContext : DbContext
{
    public PhotoAlbumContext(DbContextOptions<PhotoAlbumContext> options)
        : base(options)
    {
    }

    /// <summary>
    /// Photos collection
    /// </summary>
    public DbSet<Photo> Photos { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure Photo entity
        modelBuilder.Entity<Photo>(entity =>
        {
            // Primary key
            entity.HasKey(p => p.Id);

            // Index on UploadedAt for chronological queries
            entity.HasIndex(p => p.UploadedAt)
                .HasDatabaseName("IX_Photos_UploadedAt")
                .IsDescending();

            // Property configurations
            entity.Property(p => p.OriginalFileName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(p => p.StoredFileName)
                .IsRequired()
                .HasMaxLength(255);

            entity.Property(p => p.FilePath)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(p => p.MimeType)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(p => p.FileSize)
                .IsRequired();

            entity.Property(p => p.UploadedAt)
                .IsRequired();
        });
    }
}
