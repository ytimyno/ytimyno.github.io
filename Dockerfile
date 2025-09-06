FROM python:3
COPY . /yt-research-docs/
WORKDIR /yt-research-docs/
RUN pip install mkdocs
RUN pip install mkdocs-material
EXPOSE 8080
CMD ["mkdocs", "serve"]


# docker build -t ytimyno .
# docker run -p 8080:8080 ytimyno