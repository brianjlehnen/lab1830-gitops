#!/bin/bash
# Setup homelab-gitops repository structure

# Create directory structure
mkdir -p argocd/bootstrap
mkdir -p argocd/apps/staging
mkdir -p argocd/apps/production
mkdir -p charts/infrastructure/metallb
mkdir -p charts/infrastructure/nginx-ingress
mkdir -p charts/infrastructure/cert-manager
mkdir -p charts/applications

# Create .gitignore
cat > .gitignore << 'EOF'
# Temporary files
*.tmp
*.temp
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Kubernetes secrets (if any local ones)
*secret*.yaml
*Secret*.yaml

# Helm
*.tgz
charts/*.lock
charts/*/charts/
charts/*/Chart.lock

# Logs
*.log
EOF

# Create README.md
cat > README.md << 'EOF'
# homelab-gitops

Modern GitOps repository for Lab1830 homelab infrastructure using ArgoCD, Helm, and app-of-apps patterns.

## Repository Structure

```
homelab-gitops/
├── argocd/
│   ├── bootstrap/              # Root ArgoCD applications
│   │   ├── staging.yaml        # Bootstrap app for staging environment
│   │   └── production.yaml     # Bootstrap app for production environment
│   └── apps/
│       ├── staging/            # Staging application definitions
│       └── production/         # Production application definitions
└── charts/                     # Custom Helm charts library
    ├── infrastructure/         # Infrastructure charts
    │   ├── metallb/
    │   ├── nginx-ingress/
    │   └── cert-manager/
    └── applications/           # Application charts
        ├── homepage/
        ├── monitoring/
        └── vault/
```

## Environments

- **Staging**: `staging` branch - For testing and development
- **Production**: `main` branch - Stable production releases

## GitOps Workflow

1. **Development**: Create feature branch from `staging`
2. **Testing**: Merge to `staging` branch → Auto-deploy to staging cluster
3. **Production**: Merge `staging` to `main` → Deploy to production cluster

## Usage

### Deploy to Staging
```bash
git checkout staging
# Make changes
git commit -m "Update application"
git push origin staging
# ArgoCD automatically syncs staging environment
```

### Promote to Production
```bash
git checkout main
git merge staging
git push origin main
# ArgoCD automatically syncs production environment
```

## Applications

### Infrastructure
- MetalLB: LoadBalancer implementation
- NGINX Ingress: Traffic routing and TLS termination
- cert-manager: Automated certificate management

### Applications
- Homepage: Dashboard and service catalog
- Monitoring: Prometheus, Grafana, AlertManager stack
- Various homelab applications and services

## Repository Conventions

- **Helm charts**: All applications use Helm for templating
- **Environment-specific values**: Managed via separate values files
- **GitOps principles**: Declarative, versioned, and automatically deployed
- **App-of-apps pattern**: Hierarchical application management
EOF

# Create initial bootstrap applications
cat > argocd/bootstrap/staging.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: staging-bootstrap
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/brianjlehnen/homelab-gitops.git
    targetRevision: staging
    path: argocd/apps/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF

cat > argocd/bootstrap/production.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: production-bootstrap
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/brianjlehnen/homelab-gitops.git
    targetRevision: main
    path: argocd/apps/production
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF

# Create sample application structure - Homepage
mkdir -p charts/applications/homepage/templates

cat > charts/applications/homepage/Chart.yaml << 'EOF'
apiVersion: v2
name: homepage
description: A dashboard for your homelab services
type: application
version: 0.1.0
appVersion: "latest"
keywords:
  - dashboard
  - homepage
  - homelab
home: https://github.com/gethomepage/homepage
sources:
  - https://github.com/gethomepage/homepage
maintainers:
  - name: Lab1830
    email: admin@lab1830.com
EOF

cat > charts/applications/homepage/values.yaml << 'EOF'
# Default values for homepage
replicaCount: 1

image:
  repository: ghcr.io/gethomepage/homepage
  pullPolicy: IfNotPresent
  tag: "latest"

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 3000

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  hosts:
    - host: homepage.lab1830.com
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi

nodeSelector: {}
tolerations: []
affinity: {}

# Homepage configuration
config:
  # This will be mounted as configmaps
  bookmarks: {}
  services: {}
  widgets: {}
  kubernetes: {}
  settings: {}
EOF

cat > charts/applications/homepage/templates/_helpers.tpl << 'EOF'
{{/*
Expand the name of the chart.
*/}}
{{- define "homepage.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "homepage.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "homepage.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "homepage.labels" -}}
helm.sh/chart: {{ include "homepage.chart" . }}
{{ include "homepage.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "homepage.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homepage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
EOF

cat > charts/applications/homepage/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "homepage.fullname" . }}
  labels:
    {{- include "homepage.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "homepage.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "homepage.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 3000
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
EOF

cat > charts/applications/homepage/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "homepage.fullname" . }}
  labels:
    {{- include "homepage.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "homepage.selectorLabels" . | nindent 4 }}
EOF

cat > charts/applications/homepage/templates/ingress.yaml << 'EOF'
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "homepage.fullname" . }}
  labels:
    {{- include "homepage.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  {{- if .Values.ingress.tls }}
  tls:
    {{- range .Values.ingress.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "homepage.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
EOF

# Create ArgoCD application for staging homepage
cat > argocd/apps/staging/homepage.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homepage-staging
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/brianjlehnen/homelab-gitops.git
    targetRevision: staging
    path: charts/applications/homepage
    helm:
      valueFiles:
        - values.yaml
      values: |
        ingress:
          hosts:
            - host: homepage-staging.lab1830.com
              paths:
                - path: /
                  pathType: Prefix
        resources:
          requests:
            cpu: 25m
            memory: 32Mi
          limits:
            cpu: 100m
            memory: 128Mi
  destination:
    server: https://kubernetes.default.svc
    namespace: homepage-staging
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF

# Create ArgoCD application for production homepage  
cat > argocd/apps/production/homepage.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homepage-production
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/brianjlehnen/homelab-gitops.git
    targetRevision: main
    path: charts/applications/homepage
    helm:
      valueFiles:
        - values.yaml
      values: |
        replicaCount: 2
        ingress:
          hosts:
            - host: homepage.lab1830.com
              paths:
                - path: /
                  pathType: Prefix
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
  destination:
    server: https://kubernetes.default.svc
    namespace: homepage
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF

echo "✅ GitOps repository structure created successfully!"
echo ""
echo "📁 Repository structure:"
find . -type f -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.tpl" | sort
echo ""
echo "🚀 Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Initial GitOps repository structure with app-of-apps pattern'"
echo "3. Create GitHub repository: homelab-gitops"
echo "4. git remote add origin https://github.com/brianjlehnen/homelab-gitops.git"
echo "5. git push -u origin main"
echo "6. Create staging branch and test with ArgoCD"
