# AWS Node.js CI/CD Lab

A small one-page Express application prepared for an AWS CI/CD exercise.

## Run locally

```bash
npm install
npm test
npm start
```

Open `http://localhost:3000`. The health check is available at
`http://localhost:3000/health`.

## Run with Docker

```bash
docker build -t aws-node-cicd-lab .
docker run --rm -p 3000:3000 aws-node-cicd-lab
```

`buildspec.yml` installs dependencies, runs tests, and builds the container in
AWS CodeBuild. The next lab step can connect a source repository, CodeBuild,
Amazon ECR, and a deployment target through AWS CodePipeline.
