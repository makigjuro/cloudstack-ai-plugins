namespace Starter.Orders.Application.Commands;

public record CreateOrderCommand(Guid TenantId, string CustomerName, decimal TotalAmount);
