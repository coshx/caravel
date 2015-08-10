# HOWTO

## Release a new version

* Apply any needed change
* Update the version number within the [Gruntfile](https://github.com/coshx/caravel/blob/master/caravel/js/Gruntfile.js)
* Run the `release` target to build `caravel.min.js`
* Update the version number in the [Podspec](https://github.com/coshx/caravel/blob/master/Caravel.podspec)
* Push your changes and create a new tag. The new tag has to be created before pushing the pod.
* Run the command below to update the Pod:

   ```
   pod trunk push Caravel.podspec
   ```
