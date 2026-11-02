---
name: endpoint-conventions
description: Minimal API endpoint conventions — static MapEndpoints classes, route groups, OpenAPI metadata, handler DI, and Result-to-HTTP conversion. Apply whenever writing or editing endpoint classes.
user-invocable: false
paths:
  - "src/**/Endpoints/**/*.cs"
  - "src/**/*Endpoints*.cs"
---

# Endpoint Rules (Minimal API)

## Structure
- Define as a static class with a `MapEndpoints(this WebApplication app)` extension method
- Group routes: `var group = app.MapGroup("/api/orders").WithTags("Orders").RequireAuthorization();`
- Handler methods are `private static async Task<IResult>` methods in the same class

## OpenAPI Metadata
- Every endpoint has `.WithName()`, `.WithSummary()`, `.WithDescription()`
- Use `.Produces<T>(StatusCodes.Status200OK)` and `.ProducesProblem(StatusCodes.Status404NotFound)` for response types
- Group with `.WithTags("DomainName")`
- Do NOT use `.WithOpenApi()` -- it is deprecated in .NET 10 (ASPDEPR002) and breaks builds with `TreatWarningsAsErrors`. The document comes from `builder.Services.AddOpenApi()` + `app.MapOpenApi()` (package `Microsoft.AspNetCore.OpenApi`); per-endpoint metadata comes from the calls above

## DI in Handlers
- Inject services via parameters with `[FromServices]` attribute
- Inject route/query params with `[FromRoute]`, `[FromQuery]`, `[FromBody]`

## Result-to-HTTP Conversion
- Convert `Result<T>` to HTTP using `.ToHttpResult()` extension method
- This maps ErrorType to status codes automatically:
  - Validation -> 400, NotFound -> 404, Conflict -> 409, Unauthorized -> 401, Forbidden -> 403, Failure -> 422, Unexpected -> 500
- POST that creates a resource: `result.ToHttpResult(created => $"/api/orders/{created.Id}")` returns 201 with a `Location` header
- Failures are RFC 7807 ProblemDetails with extensions `error` (code), `message`, `errorType` (and `errors` for validation details) -- never a custom top-level `type`, which ProblemDetails already uses

## Pattern
```csharp
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
            .WithDescription("Creates a pending order for the caller's tenant.")
            .Produces<CreateOrderResponse>(StatusCodes.Status201Created)
            .ProducesProblem(StatusCodes.Status400BadRequest);
    }

    private static async Task<IResult> CreateOrder(
        [FromBody] CreateOrderRequest request,
        [FromServices] CreateOrderHandler handler,
        ClaimsPrincipal user,
        CancellationToken cancellationToken)
    {
        // TenantId comes from the token claim, never from the request body
        var command = new CreateOrderCommand(user.GetTenantId(), request.CustomerName, request.TotalAmount);
        var result = await handler.Handle(command, cancellationToken);
        return result.ToHttpResult(created => $"/api/orders/{created.Id}");
    }
}
```
