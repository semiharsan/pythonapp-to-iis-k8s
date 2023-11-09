############################DOCKER IMAGE######################################################
docker login -u $dockeruser -p "$dockerpassword"
DOCKERIMAGE_ID=$(docker images -q "$DOCKERIMAGE_NAME:$DOCKERIMAGE_TAG_VERSION")
if [ -z "$DOCKERIMAGE_ID" ]; then
    echo "Docker image '$DOCKERIMAGE_NAME' not found. Let us create it"
else
    echo "There is a docker image with id $DOCKERIMAGE_ID, let us remove it first"
    docker rmi -f $DOCKERIMAGE_ID
fi
docker build -t $DOCKERIMAGE_NAME:$DOCKERIMAGE_TAG_VERSION .
DOCKERIMAGE_ID=$(docker images -q "$DOCKERIMAGE_NAME:$DOCKERIMAGE_TAG_VERSION")
docker tag $DOCKERIMAGE_ID $DOCKERHUBURL/$DOCKERIMAGE_NAME:$DOCKERIMAGE_TAG_VERSION
docker push $DOCKERHUBURL/$DOCKERIMAGE_NAME:$DOCKERIMAGE_TAG_VERSION
############################Python App DEPLOYMENT#######################################
export KUBECONFIG=/root/.kube/config
export IMAGE_NAME=$DOCKERHUBURL/$DOCKERIMAGE_NAME:$DOCKERIMAGE_TAG_VERSION

PODS=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME -o custom-columns=NAME:.metadata.name --no-headers)
if [ -z "$PODS" ]; then
    echo "There is no $DEPLOYMENT_NAME deployment. Let us create it"
    echo "IMAGE NAME : $IMAGE_NAME"
    envsubst < onpremisek8s.yaml | kubectl apply -f -
    kubectl get pods
else
    echo "There is already pods with name $PODS let us update deployment"
    NEW_REPLICA=$((DEPLOYMENTREPLICA + 1))
    kubectl scale deployment/$DEPLOYMENT_NAME --replicas=$NEW_REPLICA
    kubectl get pods
    kubectl wait deployment/$DEPLOYMENT_NAME --for=condition=Available --timeout=120s
    echo Deleting pods: $PODS
    kubectl delete pod $PODS -n $NAMESPACE
    kubectl scale deployment/$DEPLOYMENT_NAME --replicas=$DEPLOYMENTREPLICA
    kubectl get pods
fi
############################COnfigure NGINX For Hostname#######################################
export KUBECONFIG=/root/.kube/config
CONFIGFILE="/etc/nginx/nginx.conf"
HOSTCONFIGFILE="/etc/nginx/conf.d/pythondemo.arsit.tech.conf"
export NGINXSVCIP=$(kubectl -n $NAMESPACE get svc $DEPLOYMENT_NAME-service -o jsonpath='{.spec.clusterIP}')
if [ -z "$CONFIGFILE" ]; then
    echo "Config File not found. Let us create it"
else
    echo "There is already a config file, let us remove it first"
    rm $CONFIGFILE
fi
mv nginx.conf $CONFIGFILE
echo "let us look at config file"
cat $CONFIGFILE
if [ -z "$HOSTCONFIGFILE" ]; then
    echo "Config File not found. Let us create it"
else
    echo "There is already a config file, let us remove it first"
    rm $HOSTCONFIGFILE
fi
envsubst '$IISSERVERIP,$NGINXSVCIP,$HOSTNAME' < pythondemo.arsit.tech.conf > $HOSTCONFIGFILE
echo "let us look at host config file"
cat $HOSTCONFIGFILE
service nginx restart
