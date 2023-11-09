FROM python:slim-buster

# Declaring working directory in our container and change user
WORKDIR /opt/apps

# Add pip scripts installation directory as path environment
ENV PATH=$PATH:/home/appuser/.local/bin

# Copy all relevant files to our working dir /opt/apps
COPY app/. .

#Add a new user and change to that for python security consideration
RUN adduser appuser && chown -R appuser /opt/apps
USER appuser

# As optional you can upgrade pip script to latest version.
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install -r requirements.txt

EXPOSE 8000

# Run the application
CMD [ "python3", "/opt/apps/hello.py" ]
