FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["PhotoAlbum/PhotoAlbum.csproj", "PhotoAlbum/"]
RUN dotnet restore "PhotoAlbum/PhotoAlbum.csproj"
COPY . .
WORKDIR "/src/PhotoAlbum"
RUN dotnet build "PhotoAlbum.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "PhotoAlbum.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "PhotoAlbum.dll"]
