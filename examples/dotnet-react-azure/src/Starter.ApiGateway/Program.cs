using Starter.ServiceDefaults;

// Startup failures exit with code 1 (in a container the process is PID 1, where an unhandled
// exception does not terminate the process).
try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.AddServiceDefaults();

    const string CorsPolicy = "frontend";
    var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];

    builder.Services.AddCors(options => options.AddPolicy(CorsPolicy, policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                .AllowAnyHeader()
                .AllowAnyMethod()
                .WithExposedHeaders("Location");
        }
    }));

    // Routes and clusters come from the ReverseProxy section (override the orders destination with
    // ReverseProxy__Clusters__orders__Destinations__d1__Address). YARP forwards the Authorization
    // header unchanged; the downstream services validate the JWT.
    builder.Services.AddReverseProxy()
        .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"));

    var app = builder.Build();

    app.UseCors(CorsPolicy);

    // Gateway probes are anonymous so the container platform can call them.
    app.MapDefaultEndpoints();
    app.MapReverseProxy();

    await app.RunAsync();
    return 0;
}
#pragma warning disable CA1031 // Any startup failure must surface as a non-zero exit code.
catch (Exception exception)
#pragma warning restore CA1031
{
    await Console.Error.WriteLineAsync($"Starter.ApiGateway terminated unexpectedly: {exception}");
    return 1;
}
