using FluentValidation;
using Starter.Orders.Application.Commands;
using Starter.Orders.Application.Events;
using Starter.Orders.Application.Queries;
using Starter.Orders.Application.Validators;
using Starter.Orders.Host.Endpoints;
using Starter.Orders.Infrastructure;
using Starter.Orders.Infrastructure.Persistence;
using Starter.ServiceDefaults;
using Starter.Shared.Infrastructure.Authentication;
using Wolverine;

const string MigrateArgument = "--migrate";

// Migrations-as-job: `Starter.Orders.Host --migrate` applies pending EF Core migrations and exits
// without starting the web server. Normal startup never migrates.
if (args.Contains(MigrateArgument, StringComparer.OrdinalIgnoreCase))
{
    return await RunMigrationsAsync(args.Where(arg => !string.Equals(arg, MigrateArgument, StringComparison.OrdinalIgnoreCase)).ToArray());
}

// Startup failures are caught and turned into exit code 1. In a container the process is PID 1,
// where an unhandled exception (abort) does not terminate the process and the replica would hang.
try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.AddServiceDefaults();
    builder.AddStarterAuthentication();

    builder.Services.AddProblemDetails();
    builder.Services.AddOpenApi();

    builder.Services.AddInfrastructure(builder.Configuration);

    builder.Services.AddValidatorsFromAssemblyContaining<CreateOrderValidator>();
    builder.Services.AddScoped<CreateOrderHandler>();
    builder.Services.AddScoped<GetOrderHandler>();
    builder.Services.AddScoped<ListOrdersHandler>();

    // WolverineFx dispatches domain events to convention-based handlers in the Application assembly.
    builder.Host.UseWolverine(options =>
    {
        options.Discovery.IncludeAssembly(typeof(OrderCreatedEventHandler).Assembly);
    });

    var app = builder.Build();

    app.UseExceptionHandler();
    app.UseStatusCodePages();

    app.UseAuthentication();
    app.UseAuthorization();

    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();
    }

    // Health probes are anonymous (see MapDefaultEndpoints); every /api/* route requires authorization.
    app.MapDefaultEndpoints();
    app.MapEndpoints();

    await app.RunAsync();
    return 0;
}
catch (HostAbortedException)
{
    // Raised on purpose by `dotnet ef` tooling after it captures the host; let it through.
    throw;
}
#pragma warning disable CA1031 // Any startup failure must surface as a non-zero exit code.
catch (Exception exception)
#pragma warning restore CA1031
{
    await Console.Error.WriteLineAsync($"Starter.Orders.Host terminated unexpectedly: {exception}");
    return 1;
}

static async Task<int> RunMigrationsAsync(string[] args)
{
    // Building the host is inside the try: as PID 1 in a container, an unhandled startup exception
    // would leave the job hanging instead of failing.
    try
    {
        // Same environment resolution as the web host (ASPNETCORE_ENVIRONMENT, then DOTNET_ENVIRONMENT).
        var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings
        {
            Args = args,
            EnvironmentName = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")
                ?? Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT"),
        });
        builder.ConfigureStructuredLogging();
        builder.Services.AddPersistence(builder.Configuration);

        using var host = builder.Build();
        var logger = host.Services.GetRequiredService<ILoggerFactory>().CreateLogger("Starter.Orders.Migrations");

        try
        {
            await DatabaseMigrator.MigrateAsync(host.Services);
            return 0;
        }
#pragma warning disable CA1031 // A failed migration job must log and exit non-zero, whatever the cause.
        catch (Exception exception)
#pragma warning restore CA1031
        {
            logger.LogCritical(exception, "Database migration failed");
            return 1;
        }
    }
#pragma warning disable CA1031 // A failed migration host must exit non-zero, whatever the cause.
    catch (Exception exception)
#pragma warning restore CA1031
    {
        await Console.Error.WriteLineAsync($"Starter.Orders.Host --migrate terminated unexpectedly: {exception}");
        return 1;
    }
}

/// <summary>Entry point; public so WebApplicationFactory&lt;Program&gt; can host it in integration tests.</summary>
public partial class Program;
