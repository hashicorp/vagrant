package serverinstall

import (
	"fmt"

	appsv1 "k8s.io/api/apps/v1"
	apiv1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

// NewStatefulSet creates a new Vagrant Statefulset for deployment in Kubernetes.
func (c *Config) NewStatefulSet() (*appsv1.StatefulSet, error) {
	cpuRequest, err := resource.ParseQuantity(c.CPURequest)
	if err != nil {
		return nil, fmt.Errorf("could not parse cpu request resource %s: %s", c.CPURequest, err)
	}

	memRequest, err := resource.ParseQuantity(c.MemRequest)
	if err != nil {
		return nil, fmt.Errorf("could not parse memory request resource %s: %s", c.MemRequest, err)
	}

	storageRequest, err := resource.ParseQuantity(c.StorageRequest)
	if err != nil {
		return nil, fmt.Errorf("could not parse storage request resource %s: %s", c.StorageRequest, err)
	}

	securityContext := &apiv1.PodSecurityContext{}
	if !c.OpenShift {
		securityContext.FSGroup = int64Ptr(1000)
	}

	return &appsv1.StatefulSet{
		ObjectMeta: metav1.ObjectMeta{
			Name:      c.ServerName,
			Namespace: c.Namespace,
			Labels: map[string]string{
				"app": c.ServerName,
			},
		},
		Spec: appsv1.StatefulSetSpec{
			Replicas: int32Ptr(1),
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{
					"app": c.ServerName,
				},
			},
			ServiceName: c.ServiceName,
			Template: apiv1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{
						"app": c.ServerName,
					},
				},
				Spec: apiv1.PodSpec{
					ImagePullSecrets: []apiv1.LocalObjectReference{
						{
							Name: c.ImagePullSecret,
						},
					},
					SecurityContext: securityContext,
					Containers: []apiv1.Container{
						{
							Name:            "server",
							Image:           c.ServerImage,
							ImagePullPolicy: apiv1.PullAlways,
							Env: []apiv1.EnvVar{
								{
									Name:  "HOME",
									Value: "/data",
								},
							},
							Command: []string{"vagrant"},
							Args: []string{
								"server",
								"run",
								"-accept-tos",
								"-vvv",
								"-db=/data/data.db",
								"-listen-grpc=0.0.0.0:9701",
								"-listen-http=0.0.0.0:9702",
							},
							Ports: []apiv1.ContainerPort{
								{
									Name:          "grpc",
									Protocol:      apiv1.ProtocolTCP,
									ContainerPort: 9701,
								},
								{
									Name:          "http",
									Protocol:      apiv1.ProtocolTCP,
									ContainerPort: 9702,
								},
							},
							LivenessProbe: &apiv1.Probe{
								Handler: apiv1.Handler{
									HTTPGet: &apiv1.HTTPGetAction{
										Path:   "/",
										Port:   intstr.FromString("http"),
										Scheme: "HTTPS",
									},
								},
							},
							Resources: apiv1.ResourceRequirements{
								Requests: apiv1.ResourceList{
									apiv1.ResourceMemory: memRequest,
									apiv1.ResourceCPU:    cpuRequest,
								},
							},
							VolumeMounts: []apiv1.VolumeMount{
								{
									Name:      "data",
									MountPath: "/data",
								},
							},
						},
					},
				},
			},
			VolumeClaimTemplates: []apiv1.PersistentVolumeClaim{
				{
					ObjectMeta: metav1.ObjectMeta{
						Name: "data",
					},
					Spec: apiv1.PersistentVolumeClaimSpec{
						AccessModes: []apiv1.PersistentVolumeAccessMode{apiv1.ReadWriteOnce},
						Resources: apiv1.ResourceRequirements{
							Requests: apiv1.ResourceList{
								apiv1.ResourceStorage: storageRequest,
							},
						},
					},
				},
			},
		},
	}, nil
}

// NewService creates a new Vagrant LoadBalancer for deployment in Kubernetes.
func (c *Config) NewService() (*apiv1.Service, error) {
	return &apiv1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      c.ServiceName,
			Namespace: c.Namespace,
			Labels: map[string]string{
				"app": c.ServerName,
			},
			Annotations: c.ServiceAnnotations,
		},
		Spec: apiv1.ServiceSpec{
			Ports: []apiv1.ServicePort{
				{
					Port: 9701,
					Name: "grpc",
				},
				{
					Port: 9702,
					Name: "http",
				},
			},
			Selector: map[string]string{
				"app": c.ServerName,
			},
			Type: apiv1.ServiceTypeLoadBalancer,
		},
	}, nil
}

func int32Ptr(i int32) *int32 {
	return &i
}

func int64Ptr(i int64) *int64 {
	return &i
}
