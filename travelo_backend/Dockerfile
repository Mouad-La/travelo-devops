# 1. Multi-stage build (réduit la taille finale)
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
# 2. Copier pom.xml d'abord (optimise le cache Docker)
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# 3. Image de base minimale pour l'exécution
FROM gcr.io/distroless/java21-debian12:latest
WORKDIR /app
# Mettre à jour les packages Alpine (corrige expat, openssl, libpng, sqlite...)
#RUN apk update && apk upgrade --no-cache
# 4. Utilisateur non-root (sécurité)
#RUN addgroup -S appgroup && adduser -S appuser -G appgroup
#USER appuser
USER 65532
# 5. Copier uniquement le JAR final
COPY --from=build /app/target/*.jar app.jar
# 6. Exposer le port documenté
EXPOSE 8080
# 7. Utiliser ENTRYPOINT (pas CMD seul)
ENTRYPOINT [ "java", "-jar", "app.jar" ]

