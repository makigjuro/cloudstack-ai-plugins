# syntax=docker/dockerfile:1
# Build context: examples/starter  ->  docker build -f src/Starter.ApiGateway/Dockerfile -t starter-gateway .

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

COPY global.json Directory.Build.props Directory.Packages.props .editorconfig ./
COPY src/Starter.ServiceDefaults/Starter.ServiceDefaults.csproj src/Starter.ServiceDefaults/
COPY src/Starter.ApiGateway/Starter.ApiGateway.csproj src/Starter.ApiGateway/
RUN dotnet restore src/Starter.ApiGateway/Starter.ApiGateway.csproj

COPY src/Starter.ServiceDefaults/ src/Starter.ServiceDefaults/
COPY src/Starter.ApiGateway/ src/Starter.ApiGateway/
RUN dotnet publish src/Starter.ApiGateway/Starter.ApiGateway.csproj \
    --configuration Release --no-restore --output /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080 \
    DOTNET_RUNNING_IN_CONTAINER=true
COPY --from=build --chown=$APP_UID /app/publish .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "Starter.ApiGateway.dll"]
