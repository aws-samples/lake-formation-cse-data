# from eksworkshop.com
kubectl create namespace spark
eksctl create iamidentitymapping --cluster eks-emr  --namespace spark --service-name "emr-containers"
#eksctl utils associate-iam-oidc-provider --cluster eksworkshop-eksctl --approve
#cat <<EoF > ~/environment/emr-trust-policy.json
# {
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Effect": "Allow",
#      "Principal": {
#        "Service": "elasticmapreduce.amazonaws.com"
#      },
#      "Action": "sts:AssumeRole"
#    }
#  ]
#}
#EoF

#aws iam create-role --role-name EMRContainers-JobExecutionRole --assume-role-policy-document file://~/environment/emr-trust-policy.json
aws iam create-role --role-name EMRContainers-JobExecutionRole-at --assume-role-policy-document file://emr-trust-policy.json
cat <<EoF > EMRContainers-JobExecutionRole.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}  
EoF
aws iam put-role-policy --role-name EMRContainers-JobExecutionRole-at --policy-name EMR-Containers-Job-Execution --policy-document file://EMRContainers-JobExecutionRole.json
aws iam attach-role-policy --role-name EMRContainers-JobExecutionRole-at --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole
aws iam attach-role-policy --role-name EMRContainers-JobExecutionRole-at --policy-arn arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin
aws iam attach-role-policy --role-name EMRContainers-JobExecutionRole-at --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws emr-containers update-role-trust-policy --cluster-name eks-emr --namespace spark --role-name EMRContainers-JobExecutionRole-at
aws emr-containers create-virtual-cluster \
--name eks-emr \
--container-provider '{
    "id": "eks-emr",
    "type": "EKS",
    "info": {
        "eksInfo": {
            "namespace": "spark"
        }
    }
}'

