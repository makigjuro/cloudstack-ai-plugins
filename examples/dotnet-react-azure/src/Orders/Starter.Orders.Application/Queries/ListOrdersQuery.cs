namespace Starter.Orders.Application.Queries;

public record ListOrdersQuery(Guid TenantId, int PageNumber = 1, int PageSize = 20);
