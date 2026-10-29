# syntax=docker/dockerfile:1
# Build context: examples/starter  ->  docker build -f src/Orders/Dockerfile -t starter-orders .
# Run as API:       docker run starter-orders
# Run as migration: docker run starter-orders --migrate   (Azure Container Apps Job args: ["--migrate"])

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

COPY global.json Directory.Build.props Directory.Packages.props .editorconfig ./
COPY src/Shared/Starter.Domain/Starter.Domain.csproj src/Shared/Starter.Domain/
COPY src/Shared/Starter.Shared.Infrastructure/Starter.Shared.Infrastructure.csproj src/Shared/Starter.Shared.Infrastructure/
COPY src/Starter.ServiceDefaults/Starter.ServiceDefaults.csproj src/Starter.ServiceDefaults/
COPY src/Orders/Starter.Orders.Application/Starter.Orders.Application.csproj src/Orders/Starter.Orders.Application/
COPY src/Orders/Starter.Orders.Infrastructure/Starter.Orders.Infrastructure.csproj src/Orders/Starter.Orders.Infrastructure/
COPY src/Orders/Starter.Orders.Host/Starter.Orders.Host.csproj src/Orders/Starter.Orders.Host/
RUN dotnet restore src/Orders/Starter.Orders.Host/Starter.Orders.Host.csproj

COPY src/Shared/ src/Shared/
COPY src/Starter.ServiceDefaults/ src/Starter.ServiceDefaults/
COPY src/Orders/ src/Orders/
RUN dotnet publish src/Orders/Starter.Orders.Host/Starter.Orders.Host.csproj \
    --configuration Release --no-restore --output /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true
COPY --from=build --chown=$APP_UID /app/publish .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "Starter.Orders.Host.dll"]
