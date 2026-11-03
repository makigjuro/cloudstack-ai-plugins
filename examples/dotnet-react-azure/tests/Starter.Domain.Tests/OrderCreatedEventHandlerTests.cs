using Microsoft.Extensions.Logging;
using Starter.Domain.Events;
using Starter.Domain.ValueObjects;
using Starter.Orders.Application.Events;

namespace Starter.Domain.Tests;

public class OrderCreatedEventHandlerTests
{
    private readonly ILogger<OrderCreatedEventHandler> _logger;
    private readonly OrderCreatedEventHandler _sut;

    public OrderCreatedEventHandlerTests()
    {
        _logger = Substitute.For<ILogger<OrderCreatedEventHandler>>();
        _logger.IsEnabled(Arg.Any<LogLevel>()).Returns(true);
        _sut = new OrderCreatedEventHandler(_logger);
    }

    [Fact]
    public async Task Handle_Event_LogsInformation()
    {
        // Arrange
        var @event = new OrderCreatedEvent(OrderId.New(), new TenantId(Guid.NewGuid()), DateTimeOffset.UtcNow);

        // Act
        await _sut.Handle(@event, CancellationToken.None);

        // Assert
        _logger.ReceivedWithAnyArgs(1).Log(LogLevel.Information, default, default(object), default, default!);
    }

    [Fact]
    public async Task Handle_SameEventTwice_IsIdempotent()
    {
        // Arrange
        var @event = new OrderCreatedEvent(OrderId.New(), new TenantId(Guid.NewGuid()), DateTimeOffset.UtcNow);

        // Act
        var act = async () =>
        {
            await _sut.Handle(@event, CancellationToken.None);
            await _sut.Handle(@event, CancellationToken.None);
        };

        // Assert
        await act.Should().NotThrowAsync();
    }
}
