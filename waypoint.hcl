# The name of your project. A project typically maps 1:1 to a VCS repository.
# This name must be unique for your Waypoint server. If you're running in
# local mode, this must be unique to your machine.
project = "webserver"

# Labels can be specified for organizational purposes.
# labels = { "foo" = "bar" }

# An application to deploy.

variable "username" {
  type = string
  default = "vagrant"
#  default = dynamic("kubernetes", {
#    name = "user-configmap"
#    key = "username"
#  })
  env = ["USERNAME"]
}

variable "password" {
  type = string
  default = "pass"
#  default = dynamic("kubernetes", {
#    name = "user-configmap"
#    key = "password"
#  })
  env = ["PASSWORD"]
}

app "web" {
    # Build specifies how an application should be deployed. In this case,
    # we'll build using a Dockerfile and keeping it in a local registry.
    build {
        use "docker" {
            build_args {
                USER = var.username
#              PASS = base64decode(var.password)
              PASS = var.password
            }
        }
        
        # Uncomment below to use a remote docker registry to push your built images.

         registry {
           use "docker" {
             image = "saveloy/nginx"
             tag   = "1.0"
           }
         }
    }

    # Deploy to kubernetes
    deploy {
        use "kubernetes-apply" {
          path = templatedir("${path.app}/k8s")
          prune_label = "app=nginx"
        }
    }
}
