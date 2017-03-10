/*
 * Copyright 2016 GantSign Ltd. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.gantsign.restrulz.generator

import com.gantsign.restrulz.restdsl.BodyTypeRef
import com.gantsign.restrulz.restdsl.ClassType
import com.gantsign.restrulz.restdsl.IntegerType
import com.gantsign.restrulz.restdsl.MethodParameter
import com.gantsign.restrulz.restdsl.PathElement
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.PathScope
import com.gantsign.restrulz.restdsl.Property
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.RequestMapping
import com.gantsign.restrulz.restdsl.Response
import com.gantsign.restrulz.restdsl.ResponseOptionalBody
import com.gantsign.restrulz.restdsl.ResponseWithBody
import com.gantsign.restrulz.restdsl.ResponseWithoutBody
import com.gantsign.restrulz.restdsl.SimpleType
import com.gantsign.restrulz.restdsl.Specification
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StatusForbiddenBody
import com.gantsign.restrulz.restdsl.StatusOptionalBody
import com.gantsign.restrulz.restdsl.StatusRequiresBody
import com.gantsign.restrulz.restdsl.StringType
import com.google.gson.stream.JsonWriter
import java.io.StringWriter
import java.util.regex.Pattern
import java.util.stream.Collectors
import java.util.stream.Stream
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

/**
 * Generates code from your model files on save.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class RestdslGenerator extends AbstractGenerator {
	private val defaultType = "default-type"
	private val lineEndPattern = Pattern.compile("\\r\\n|\\n|\\r");

	private def writeProperties(BodyTypeRef param, JsonWriter writer) {
		writer.name("kind").value("body-param-ref")
		writer.name("type-ref").value(param.ref.name)
	}

	private def writeProperties(PathParamRef param, JsonWriter writer) {
		writer.name("kind").value("path-param-ref")
		writer.name("value-ref").value(param.ref.name)
	}

	private def writeObject(MethodParameter param, JsonWriter writer) {
		writer.beginObject

		writer.name("name").value(param.name)

		val paramValue = param.value
		switch (paramValue) {
			PathParamRef: paramValue.writeProperties(writer)
			BodyTypeRef: paramValue.writeProperties(writer)
			default: throw new AssertionError("Unsupported parameter: " + paramValue.class.name)
		}

		writer.endObject
	}

	private def writeProperties(RequestHandler handler, JsonWriter writer) {
		writer.name("kind").value("http-method")
		writer.name("method").value(handler.method.getName())
		writer.name("name").value(handler.name)

		writer.name("parameters")
		writer.beginArray
		handler.parameters.forEach [ param |
			param.writeObject(writer)
		]
		writer.endArray

		writer.name("response-refs")
		writer.beginArray
		handler.responses.forEach [ response |
			writer.value(response.ref.name)
		]
		writer.endArray
	}

	private def writeObject(RequestMapping mapping, JsonWriter writer) {
		writer.beginObject

		switch (mapping) {
			RequestHandler: mapping.writeProperties(writer)
			default: throw new AssertionError("Unsupported mapping: " + mapping.class.name)
		}

		writer.endObject
	}

	private def writeProperties(PathParam element, JsonWriter writer) {
		writer.name("kind").value("path-param")
		writer.name("name").value(element.name)
		writer.name("type-ref")
		if (element.type == null) {
			writer.value(defaultType)
		} else {
			writer.value(element.type.name)
		}
	}

	private def writeProperties(StaticPathElement element, JsonWriter writer) {
		writer.name("kind").value("static")
		writer.name("value").value(element.value)
	}

	private def writeObject(PathElement element, JsonWriter writer) {
		writer.beginObject

		switch (element) {
			StaticPathElement: element.writeProperties(writer)
			PathParam: element.writeProperties(writer)
			default: throw new AssertionError("Unsupported path element type: " + element.class.name)
		}

		writer.endObject
	}

	private def writeObject(PathScope pathScope, JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(pathScope.name)

		writer.name("path")
		writer.beginArray

		pathScope.path.elements.forEach [ element |
			element.writeObject(writer)
		]

		writer.endArray

		writer.name("mappings")
		writer.beginArray
		pathScope.mappings.forEach [ mapping |
			mapping.writeObject(writer)
		]
		writer.endArray

		writer.endObject
	}

	private def code(StatusRequiresBody status) {
		return Integer.parseInt(status.getName().substring("HTTP_".length))
	}

	private def code(StatusOptionalBody status) {
		return Integer.parseInt(status.getName().substring("HTTP_".length))
	}

	private def code(StatusForbiddenBody status) {
		return Integer.parseInt(status.getName().substring("HTTP_".length))
	}

	private def writeProperties(ResponseWithBody response, JsonWriter writer) {
		writer.name("status").value(response.status.code)
		writer.name("body-type-ref").value(response.body.name)
		writer.name("array").value(response.isArray)
	}

	private def writeProperties(ResponseOptionalBody response, JsonWriter writer) {
		writer.name("status").value(response.status.code)
		if (response.body != null) {
			writer.name("body-type-ref").value(response.body.name)
			writer.name("array").value(response.isArray)
		}
	}

	private def writeProperties(ResponseWithoutBody response, JsonWriter writer) {
		writer.name("status").value(response.status.code)
	}

	private def writeObject(Response response, JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(response.name)
		val detail = response.detail
		switch (detail) {
			ResponseWithBody: detail.writeProperties(writer)
			ResponseOptionalBody: detail.writeProperties(writer)
			ResponseWithoutBody: detail.writeProperties(writer)
			default: throw new AssertionError("Unsupported detail type: " + detail.class.name)
		}
		writer.endObject
	}

	private def writeObject(Property property, JsonWriter writer) {
		val type = property.type
		writer.beginObject
		writer.name("name").value(property.name)
		writer.name("type-ref")
		val fixedType = property.fixedType
		if (type == null) {
			if (fixedType == null) {
				writer.value(defaultType)
			} else {
				writer.value(fixedType)
				if (!property.isArray) {
					writer.name("allow-null").value(property.isAllowNull)
				}
			}
		} else {
			writer.value(property.type.name)
			if (!property.isArray) {
				if(type instanceof StringType) {
					writer.name("allow-empty").value(property.isAllowEmpty)
				} else if(type instanceof IntegerType || type instanceof ClassType) {
					writer.name("allow-null").value(property.isAllowNull)
				} else {
					throw new AssertionError("Unsupported type: " + type.class.name)
				}
			}
		}
		writer.name("array").value(property.isArray)
		writer.endObject
	}

	private def writeObject(ClassType classType, JsonWriter writer) {
		writer.beginObject

		writer.name("name").value(classType.name)

		writer.name("properties")
		writer.beginArray
		classType.properties.forEach [ property |
			property.writeObject(writer)
		]
		writer.endArray

		writer.endObject
	}

	private def writeProperties(StringType stringType, JsonWriter writer) {
		writer.name("kind").value("string")
		writer.name("pattern").value(stringType.pattern)
		writer.name("min-length").value(stringType.minLength)
		writer.name("max-length").value(stringType.maxLength)
	}

	private def writeProperties(IntegerType integerType, JsonWriter writer) {
		writer.name("kind").value("integer")
		writer.name("minimum").value(integerType.minimum)
		writer.name("maximum").value(integerType.maximum)
	}

	private def writeObject(SimpleType simpleType, JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(simpleType.name)
		switch (simpleType) {
			StringType: simpleType.writeProperties(writer)
			IntegerType: simpleType.writeProperties(writer)
			default: throw new AssertionError("Unsupported restriction type: " + simpleType.class.name)
		}
		writer.endObject
	}

	private def usesDefaultType(Specification spec) {
		val propertyUsesDefaultType = spec.classTypes.findFirst [ classType |
			classType.properties.findFirst [ property |
				property.type == null && property.fixedType == null
			] != null
		] != null

		if (propertyUsesDefaultType) {
			return true
		}

		val pathParamUsesDefaultType = spec.pathScopes.findFirst [ pathScope |
			pathScope.path.elements.filter(PathParam).findFirst [ pathParam |
				pathParam.type == null
			] != null
		] != null

		return pathParamUsesDefaultType
	}

	private def hasSimpleType(Specification spec, String typeName) {
		spec.simpleTypes.findFirst [ simpleType |
			typeName.equals(simpleType.name)
		] != null
	}

	private def writeDefaultType(JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(defaultType)
		writer.name("kind").value("string")
		writer.name("pattern").value("^[\\p{Alpha}]+$")
		writer.name("min-length").value(1)
		writer.name("max-length").value(100)
		writer.endObject
	}

	private def measureMargin(String line) {
		val chars = line.toCharArray
		var margin = 0
		for (var i = 0; i < chars.length; i++) {
			val c = chars.get(i)
			switch c {
				case ' ': margin++
				case '\t': margin += 4
				default: return margin
			}
		}
		return margin;
	}

	private def measureMargin(String[] lines) {
		return Stream.of(lines)
				.skip(1)
				.filter([line|!line.trim.isEmpty])
				.mapToInt([line|line.measureMargin])
				.max.orElse(0)
	}

	private def trimMargin(String line, int width) {
		val chars = line.toCharArray
		var margin = 0
		for (var i = 0; i < chars.length; i++) {
			val c = chars.get(i)
			switch c {
				case ' ': margin++
				case '\t': margin += 4
			}
			if (margin == width) {
				return line.substring(i + 1)
			}
		}
		return ""
	}

	private def rtrim(String value) {
		var len = value.length;
		while (len > 0 && value.charAt(len - 1) <= ' ') {
			len--;
		}
		return if (len < value.length) value.substring(0, len) else value
	}

	private def trimMargin(String value) {
		if (value == null) {
			return "";
		}

		val lines = lineEndPattern.split(value)

		if (lines.length == 1) {
			return lines.head
		}

		val marginWidth = lines.measureMargin;

		val head = Stream.of(lines.head)
				.filter([line|!line.trim.isEmpty])

		val body = Stream.of(lines)
				.skip(1)
				.limit(Math.max(lines.length - 2, 0))
				.map([line|line.trimMargin(marginWidth)])

		val tail = Stream.of(lines.last)
				.filter([line|!line.trim.isEmpty])
				.map([line|line.trimMargin(marginWidth)])

		return Stream.concat(Stream.concat(head, body), tail)
				.map([line|line.rtrim])
				.collect(Collectors.joining("\n"))
	}

	private def toJson(Specification spec) {
		val buf = new StringWriter()
		val writer = new JsonWriter(buf);
		writer.indent = "  ";
		writer.beginObject

		writer.name("name").value(spec.name)
		writer.name("title").value(trimMargin(spec.doc?.title))
		writer.name("description").value(trimMargin(spec.doc?.description))
		writer.name("version").value(trimMargin(spec.doc?.version))

		writer.name("simple-types")
		writer.beginArray
		if (!spec.hasSimpleType(defaultType) && spec.usesDefaultType) {
			writeDefaultType(writer)
		}
		spec.simpleTypes.forEach [ simpleType |
			simpleType.writeObject(writer)
		]
		writer.endArray

		writer.name("class-types")
		writer.beginArray
		spec.classTypes.forEach [ classType |
			classType.writeObject(writer)
		]
		writer.endArray

		writer.name("responses")
		writer.beginArray
		spec.responses.forEach [ response |
			response.writeObject(writer)
		]
		writer.endArray

		writer.name("path-scopes")
		writer.beginArray
		spec.pathScopes.forEach [ pathScope |
			pathScope.writeObject(writer)
		]
		writer.endArray

		writer.endObject
		writer.close
		return buf.toString()
	}

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		for (spec : resource.allContents.toIterable.filter(Specification)) {
			val fileName = spec.name + '.rrd.json'
			fsa.generateFile(fileName, spec.toJson)
		}
	}

}
