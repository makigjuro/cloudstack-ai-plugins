using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Starter.Orders.Infrastructure.Persistence;

namespace Starter.Orders.Tests.Integration;

/// <summary>Exercises the same code path as the <c>--migrate</c> job against an empty database.</summary>
[Trait("Category", "Integration")]
public class MigrationIntegrationTests : IClassFixture<IntegrationTestFactory>
{
    private readonly IntegrationTestFactory _factory;

    public MigrationIntegrationTests(IntegrationTestFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    [Trait("Category", "Integration")]
    public async Task MigrateAsync_EmptyDatabase_AppliesAllMigrationsAndMatchesModel()
    {
        // Arrange
        await using (var scope = _factory.Services.CreateAsyncScope())
        {
            await scope.ServiceProvider.GetRequiredService<OrdersDbContext>().Database.EnsureDeletedAsync(TestContext.Current.CancellationToken);
        }

        // Act
        await DatabaseMigrator.MigrateAsync(_factory.Services, TestContext.Current.CancellationToken);

        // Assert
        await using var assertScope = _factory.Services.CreateAsyncScope();
        var dbContext = assertScope.ServiceProvider.GetRequiredService<OrdersDbContext>();
        (await dbContext.Database.GetPendingMigrationsAsync(TestContext.Current.CancellationToken)).Should().BeEmpty();
        (await dbContext.Database.GetAppliedMigrationsAsync(TestContext.Current.CancellationToken)).Should().NotBeEmpty();
        dbContext.Database.HasPendingModelChanges().Should().BeFalse();
        (await dbContext.Orders.CountAsync(TestContext.Current.CancellationToken)).Should().Be(0);
    }
}
