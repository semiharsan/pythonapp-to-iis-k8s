from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return "Congratulations, You have deployed Python Application on Windows IIS Server and Kubernetes Cluster. You are very good at Devops. "

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
