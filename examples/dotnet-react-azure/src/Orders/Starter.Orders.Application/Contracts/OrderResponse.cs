namespace Starter.Orders.Application.Contracts;

public record OrderResponse(Guid Id, string CustomerName, decimal TotalAmount, string Status, DateTimeOffset CreatedAt);
