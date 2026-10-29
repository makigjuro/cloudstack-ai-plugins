using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Starter.Orders.Application.Commands;
using Starter.Orders.Application.Contracts;
using Starter.Orders.Application.Queries;
using Starter.Shared.Infrastructure.Authentication;
using Starter.Shared.Infrastructure.Results;

namespace Starter.Orders.Host.Endpoints;

public static class OrderEndpoints
{
    public static void MapEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/orders")
            .WithTags("Orders")
            .RequireAuthorization();

        group.MapPost("/", CreateOrder)
            .WithName("CreateOrder")
            .WithSummary("Create a new order")
            .WithDescription("Creates a pending order for the caller's tenant and returns its id. The Location header points at the new order.")
            .Produces<CreateOrderResponse>(StatusCodes.Status201Created)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("/{id:guid}", GetOrder)
            .WithName("GetOrder")
            .WithSummary("Get an order by id")
            .WithDescription("Returns a single order owned by the caller's tenant.")
            .Produces<OrderResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapGet("/", ListOrders)
            .WithName("ListOrders")
            .WithSummary("List orders")
            .WithDescription("Returns a page of the caller's tenant orders, newest first.")
            .Produces<OrderListResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized);
    }

    private static async Task<IResult> CreateOrder(
        [FromBody] CreateOrderRequest request,
        [FromServices] CreateOrderHandler handler,
        ClaimsPrincipal user,
        CancellationToken cancellationToken)
    {
        var command = new CreateOrderCommand(user.GetTenantId(), request.CustomerName, request.TotalAmount);
        var result = await handler.Handle(command, cancellationToken);
        return result.ToHttpResult(created => $"/api/orders/{created.Id}");
    }

    private static async Task<IResult> GetOrder(
        [FromRoute] Guid id,
        [FromServices] GetOrderHandler handler,
        ClaimsPrincipal user,
        CancellationToken cancellationToken)
    {
        var query = new GetOrderQuery(user.GetTenantId(), id);
        var result = await handler.Handle(query, cancellationToken);
        return result.ToHttpResult();
    }

    private static async Task<IResult> ListOrders(
        [FromServices] ListOrdersHandler handler,
        ClaimsPrincipal user,
        CancellationToken cancellationToken,
        [FromQuery] int pageNumber = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = new ListOrdersQuery(user.GetTenantId(), pageNumber, pageSize);
        var result = await handler.Handle(query, cancellationToken);
        return result.ToHttpResult();
    }
}
