# PhotoAlbum - Servlet/JSP Photo Gallery

A simple photo gallery web application built with pure Servlet/JSP and H2 in-memory database.

## Prerequisites

- Java 11+
- Apache Maven 3.6+
- Application Server: Tomcat 8.5+ / GlassFish 7 / WebSphere Liberty 25.x

## Quick Start

### 1. Build

```bash
mvn clean package
```

### 2. Deploy (choose one)

**GlassFish:**
```bash
cp target/photo-album.war $GLASSFISH_HOME/glassfish/domains/domain1/autodeploy/
$GLASSFISH_HOME/bin/asadmin start-domain
# Access: http://localhost:8080/photo-album/
```

**WebSphere Liberty:**
```bash
cp target/photo-album.war $WLP_HOME/usr/servers/defaultServer/dropins/
$WLP_HOME/bin/server run defaultServer
# Access: http://localhost:9080/photo-album/
```

**Tomcat:**
```bash
cp target/photo-album.war $CATALINA_HOME/webapps/
$CATALINA_HOME/bin/catalina.sh run
# Access: http://localhost:8080/photo-album/
```

### 3. Stop Server

**GlassFish:**
```bash
$GLASSFISH_HOME/bin/asadmin stop-domain domain1
```

**WebSphere Liberty:**
```bash
$WLP_HOME/bin/server stop defaultServer
```

**Tomcat:**
```bash
$CATALINA_HOME/bin/catalina.sh stop
```

## Tech Stack

- Jakarta Servlet 6.0 / JSP 3.1 / JSTL 3.0
- Pure JDBC (no ORM)
- H2 2.2.224 in-memory database (auto-initialized)
- Apache Maven 3.6+ build
