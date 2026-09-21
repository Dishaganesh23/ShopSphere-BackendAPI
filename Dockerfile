
# ShopSphere Backend API — Person C
# Builds a container image for this FastAPI service.
# Person D will add this into the shared docker-compose.yml (see snippet
# in README.md) so the whole system starts with one `docker compose up`.

FROM python:3.12-slim

WORKDIR /app

# Install dependencies first so Docker can cache this layer
# (rebuilds are fast unless requirements.txt actually changes)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . .

EXPOSE 8000

# --reload is for local dev only; drop it for a production image later
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
