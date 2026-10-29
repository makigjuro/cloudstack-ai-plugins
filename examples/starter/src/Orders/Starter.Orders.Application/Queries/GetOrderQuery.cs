namespace Starter.Orders.Application.Queries;

public record GetOrderQuery(Guid TenantId, Guid Id);
