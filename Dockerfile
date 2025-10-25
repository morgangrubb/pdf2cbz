FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    poppler-utils \
    zip \
    bash

# Create working directory
WORKDIR /work

# Copy the conversion script
COPY pdf2cbz.sh /usr/local/bin/pdf2cbz.sh
RUN chmod +x /usr/local/bin/pdf2cbz.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/pdf2cbz.sh"]
