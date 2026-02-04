# Portfolio

Extended Portfolio & Personal Blog

This repository contains the source for my portfolio as a personal blog & journal.

And yes - it is public. This is not a normal portfolio, or even at its best, just a blog.

This is a full-scale DevOps Playground, a mini infrastructure project.

## Implementation

### Web Server

The project utilizes FastAPI as its primary web server. FastAPI is a modern Python framework for building APIs.

The web server has been used for:

**Handle Requests**
- Enables the application to accept incoming HTTP requests from clients
- Primary client platform is browsers
- If the project becomes a huge success (I hope it will), the application can be extended to handle traffic from mobile apps, USSD gateways, and other servers

**Routing**
- Determines which piece of code should handle the request based on the URL path and HTTP method (GET, POST, PUT, DELETE, etc.)

**Executing Business Logic**
- Database queries
- Data processing
- Authentication and authorization checks
- File handling
- Integration with other APIs

**Generating Responses**
- Formats and returns HTTP responses to the client
- Dominant format used is JSON, HTML templates, files, and plain text (parsed MARKDOWN strings)

**Middleware & Hooks**
- Logging requests/responses
- Error handling
- Authentication/authorization
- Rate limiting
- Compression and caching

### Database Server
This application uses Postgres as its primary database server. The blog posts are stored as TEXT (In markdown format) in `blogs` table. You might come across JSONB a lot. I mean, really alot. Most of the content here are unstructured. Might as well migrate to Mongo DB later. My database server uses the client-server model. it gets requests from client devices (routed via FastAPI server, of course) and their users and then send back the response that was asked for. I choose to host my database server locally for cost efficiency. I mean, it's just a portfolio. I don't expect much traffic. If you choose to fork the repository and use on your own projects, please consider RDBMS in an event of usage spike.

### Content Rendering
The application uses server side rendering to deliver web pages. It is my primary choice for speed. All my projects utilize architectural styles, speed of delivery being my primary concern.

## System Design
I've Developed as a single microservice Conteinerized with docker:
`Dockerfile`
```
FROM python:3.13.2-slim

WORKDIR /app

COPY . /app

RUN pip install -r requirements.txt
```

`docker-compose.yaml`:
```
services:
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    volumes:
      - .:/app
    ports:
      - 8000:8000
    depends_on:
      - db
    environment:
      - POSTGRES_SERVER=${POSTGRES_SERVER}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}

volumes:
  postgres_data:
```




