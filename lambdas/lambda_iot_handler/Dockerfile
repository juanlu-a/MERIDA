# Lambda Container Image for IoT Handler
# Uses AWS Lambda Python 3.12 base image (more stable)

FROM public.ecr.aws/lambda/python:3.12

# Copy requirements first (better caching)
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip3 install -r ${LAMBDA_TASK_ROOT}/requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy function code
COPY app.py ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD [ "app.lambda_handler" ]

