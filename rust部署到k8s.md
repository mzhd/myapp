# Rust部署到K8s

# docker

```shell
#构建镜像
docker build -t myapp .
#运行容器
docker run -p 8000:8000 --name myapp myapp
```

# k8s

### 将docker镜像复制到containerd

使用Docker命令将所需的Docker镜像导出为tar文件：

```shell
#myapp为镜像名
docker save -o myapp-image.tar myapp
```

将`<image-name>`替换为您要复制的Docker镜像的名称。

使用Containerd的ctr工具将tar文件导入为Containerd镜像：

```shell
#一定要加上-n=k8s.io，否则crictl看不到，且K8s用不了
#一定要加上-n=k8s.io，否则crictl看不到，且K8s用不了
#一定要加上-n=k8s.io，否则crictl看不到，且K8s用不了
ctr -n=k8s.io image import myapp-image.tar 
```

这将使用ctr工具将tar文件中的镜像导入到Containerd。

确认镜像已成功导入：

```
crictl image ls 
```

这将显示Containerd中已导入的镜像列表，并且您应该能够看到刚刚导入的镜像。

### helm安装

1、创建模板

```shell
helm create my-app-chart
```

2、修改values.yaml

```yaml
image:
  repository: docker.io/library/myapp 
  pullPolicy: Never
  # Overrides the image tag whose default is the chart appVersion.
  tag: "latest"
  
service:
  type: NodePort
  #这是服务（service）的端口号
  port: 8000
  #这是容器的端口号
  targetPort: 8000
  #这是节点的端口号
  nodePort: 30008

```

3、修改Depoyment.yaml

```yaml
livenessProbe:
  httpGet:
   #修改这里
    path:  /
    #修改这里
    port: {{ .Values.service.targetPort }} 
readinessProbe:
  httpGet:
   #修改这里
    path: /
    #修改这里
    port: {{ .Values.service.targetPort }} 
	
```

4、修改service.yaml

```shell
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }} 
      targetPort: {{.Values.service.targetPort}} 
      nodePort: {{.Values.service.nodePort}} 
      protocol: TCP
      name: http
  selector:
    {{- include "my-app.selectorLabels" . | nindent 4 }}
```



5、部署

```shell
#安装
helm install my-app-rust my-app-chart
#卸载
helm uninstall my-app-rust my-app-chart
```



