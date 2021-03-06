package org.kevem.common

class Resources

fun loadFromClasspath(path: String): String {
    return Resources::class.java.classLoader.getResource(path)
        ?.readText()
        ?: throw IllegalStateException("not found on classpath - $path")
}