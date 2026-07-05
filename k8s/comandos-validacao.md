=========================================
   TECH CHALLENGE - EVIDÊNCIAS
=========================================

===== DATA =====
Sun Jul  5 07:05:40 PM UTC 2026

===== CLUSTER =====
arn:aws:eks:us-east-1:876908012464:cluster/togglemaster-cluster

===== NODES =====
NAME                         STATUS   ROLES    AGE    VERSION                INTERNAL-IP   EXTERNAL-IP     OS-IMAGE                        KERNEL-VERSION                    CONTAINER-RUNTIME
ip-10-0-2-238.ec2.internal   Ready    <none>   148m   v1.32.13-eks-7d6f6ec   10.0.2.238    44.202.73.120   Amazon Linux 2023.12.20260622   6.1.175-219.357.amzn2023.x86_64   containerd://2.2.4+unknown

===== NAMESPACE =====
NAME              STATUS   AGE
default           Active   154m
kube-node-lease   Active   154m
kube-public       Active   154m
kube-system       Active   154m
togglemaster      Active   36m

===== PODS =====
NAME                                  READY   STATUS    RESTARTS   AGE    IP           NODE                         NOMINATED NODE   READINESS GATES
analytics-service-745c98c875-qmmn4    1/1     Running   0          15m    10.0.2.168   ip-10-0-2-238.ec2.internal   <none>           <none>
auth-service-67f9f97c56-6gnmv         1/1     Running   0          16m    10.0.2.6     ip-10-0-2-238.ec2.internal   <none>           <none>
evaluation-service-6d4cb56d45-rvsfw   1/1     Running   0          4m6s   10.0.2.52    ip-10-0-2-238.ec2.internal   <none>           <none>
flag-service-9d67ccc84-xkn7w          1/1     Running   0          15m    10.0.2.99    ip-10-0-2-238.ec2.internal   <none>           <none>
postgres-auth-79b7d4df5b-56sxr        1/1     Running   0          18m    10.0.2.22    ip-10-0-2-238.ec2.internal   <none>           <none>
postgres-main-b74c6985b-tv2p2         1/1     Running   0          18m    10.0.2.8     ip-10-0-2-238.ec2.internal   <none>           <none>
targeting-service-85b57dbc7b-q2xrj    1/1     Running   0          15m    10.0.2.41    ip-10-0-2-238.ec2.internal   <none>           <none>

===== DEPLOYMENTS =====
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
analytics-service    1/1     1            1           20m
auth-service         1/1     1            1           20m
evaluation-service   1/1     1            1           20m
flag-service         1/1     1            1           20m
postgres-auth        1/1     1            1           18m
postgres-main        1/1     1            1           18m
targeting-service    1/1     1            1           20m

===== SERVICES =====
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
analytics-service    ClusterIP   172.20.253.18    <none>        8005/TCP   20m
auth-service         ClusterIP   172.20.107.89    <none>        8001/TCP   20m
evaluation-service   ClusterIP   172.20.218.143   <none>        8004/TCP   20m
flag-service         ClusterIP   172.20.160.98    <none>        8002/TCP   20m
postgres-auth        ClusterIP   172.20.148.1     <none>        5432/TCP   18m
postgres-main        ClusterIP   172.20.147.30    <none>        5432/TCP   18m
targeting-service    ClusterIP   172.20.149.88    <none>        8003/TCP   20m

===== ENDPOINTS =====
NAME                 ENDPOINTS         AGE
analytics-service    10.0.2.168:8005   20m
auth-service         10.0.2.6:8001     20m
evaluation-service   10.0.2.52:8004    20m
flag-service         10.0.2.99:8002    20m
postgres-auth        10.0.2.22:5432    18m
postgres-main        10.0.2.8:5432     18m
targeting-service    10.0.2.41:8003    20m

===== CONFIGMAP =====
NAME                  DATA   AGE
kube-root-ca.crt      1      36m
togglemaster-config   10     34m

===== ECR =====
-----------------------------------------------------------------------------------------------------------
|                                          DescribeRepositories                                           |
+---------------------------------------------------------------------------------------------------------+
||                                             repositories                                              ||
|+----------------------+--------------------------------------------------------------------------------+|
||  createdAt           |  2026-07-05T14:52:52.185000+00:00                                              ||
||  imageTagMutability  |  MUTABLE                                                                       ||
||  registryId          |  876908012464                                                                  ||
||  repositoryArn       |  arn:aws:ecr:us-east-1:876908012464:repository/togglemaster/auth-service       ||
||  repositoryName      |  togglemaster/auth-service                                                     ||
||  repositoryUri       |  876908012464.dkr.ecr.us-east-1.amazonaws.com/togglemaster/auth-service        ||
|+----------------------+--------------------------------------------------------------------------------+|
|||                                       encryptionConfiguration                                       |||
||+----------------------------------------------------------------+------------------------------------+||
|||  encryptionType                                                |  AES256                            |||
||+----------------------------------------------------------------+------------------------------------+||
|||                                     imageScanningConfiguration                                      |||
||+----------------------------------------------------------------+------------------------------------+||
|||  scanOnPush                                                    |  True                              |||
||+----------------------------------------------------------------+------------------------------------+||
||                                             repositories                                              ||
|+---------------------+---------------------------------------------------------------------------------+|
||  createdAt          |  2026-07-05T14:52:54.680000+00:00                                               ||
||  imageTagMutability |  MUTABLE                                                                        ||
||  registryId         |  876908012464                                                                   ||
||  repositoryArn      |  arn:aws:ecr:us-east-1:876908012464:repository/togglemaster/targeting-service   ||
||  repositoryName     |  togglemaster/targeting-service                                                 ||
||  repositoryUri      |  876908012464.dkr.ecr.us-east-1.amazonaws.com/togglemaster/targeting-service    ||
|+---------------------+---------------------------------------------------------------------------------+|
|||                                       encryptionConfiguration                                       |||
||+----------------------------------------------------------------+------------------------------------+||
|||  encryptionType                                                |  AES256                            |||
||+----------------------------------------------------------------+------------------------------------+||
|||                                     imageScanningConfiguration                                      |||
||+----------------------------------------------------------------+------------------------------------+||
|||  scanOnPush                                                    |  True                              |||
||+----------------------------------------------------------------+------------------------------------+||
||                                             repositories                                              ||
|+--------------------+----------------------------------------------------------------------------------+|
||  createdAt         |  2026-07-05T14:52:55.988000+00:00                                                ||
||  imageTagMutability|  MUTABLE                                                                         ||
||  registryId        |  876908012464                                                                    ||
||  repositoryArn     |  arn:aws:ecr:us-east-1:876908012464:repository/togglemaster/evaluation-service   ||
||  repositoryName    |  togglemaster/evaluation-service                                                 ||
||  repositoryUri     |  876908012464.dkr.ecr.us-east-1.amazonaws.com/togglemaster/evaluation-service    ||
|+--------------------+----------------------------------------------------------------------------------+|
|||                                       encryptionConfiguration                                       |||
||+----------------------------------------------------------------+------------------------------------+||
|||  encryptionType                                                |  AES256                            |||
||+----------------------------------------------------------------+------------------------------------+||
|||                                     imageScanningConfiguration                                      |||
||+----------------------------------------------------------------+------------------------------------+||
|||  scanOnPush                                                    |  True                              |||
||+----------------------------------------------------------------+------------------------------------+||
||                                             repositories                                              ||
|+---------------------+---------------------------------------------------------------------------------+|
||  createdAt          |  2026-07-05T14:52:57.240000+00:00                                               ||
||  imageTagMutability |  MUTABLE                                                                        ||
||  registryId         |  876908012464                                                                   ||
||  repositoryArn      |  arn:aws:ecr:us-east-1:876908012464:repository/togglemaster/analytics-service   ||
||  repositoryName     |  togglemaster/analytics-service                                                 ||
||  repositoryUri      |  876908012464.dkr.ecr.us-east-1.amazonaws.com/togglemaster/analytics-service    ||
|+---------------------+---------------------------------------------------------------------------------+|
|||                                       encryptionConfiguration                                       |||
||+----------------------------------------------------------------+------------------------------------+||
|||  encryptionType                                                |  AES256                            |||
||+----------------------------------------------------------------+------------------------------------+||
|||                                     imageScanningConfiguration                                      |||
||+----------------------------------------------------------------+------------------------------------+||
|||  scanOnPush                                                    |  True                              |||
||+----------------------------------------------------------------+------------------------------------+||
||                                             repositories                                              ||
|+----------------------+--------------------------------------------------------------------------------+|
||  createdAt           |  2026-07-05T14:52:53.433000+00:00                                              ||
||  imageTagMutability  |  MUTABLE                                                                       ||
||  registryId          |  876908012464                                                                  ||
||  repositoryArn       |  arn:aws:ecr:us-east-1:876908012464:repository/togglemaster/flag-service       ||
||  repositoryName      |  togglemaster/flag-service                                                     ||
||  repositoryUri       |  876908012464.dkr.ecr.us-east-1.amazonaws.com/togglemaster/flag-service        ||
|+----------------------+--------------------------------------------------------------------------------+|
|||                                       encryptionConfiguration                                       |||
||+----------------------------------------------------------------+------------------------------------+||
|||  encryptionType                                                |  AES256                            |||
||+----------------------------------------------------------------+------------------------------------+||
|||                                     imageScanningConfiguration                                      |||
||+----------------------------------------------------------------+------------------------------------+||
|||  scanOnPush                                                    |  True                              |||
||+----------------------------------------------------------------+------------------------------------+||

===== GITHUB ACTIONS =====

=========================================
        FIM DAS EVIDÊNCIAS
=========================================
