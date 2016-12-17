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
import com.gantsign.restrulz.restdsl.MethodParameter
import com.gantsign.restrulz.restdsl.Model
import com.gantsign.restrulz.restdsl.PathElement
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.PathScope
import com.gantsign.restrulz.restdsl.Property
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.RequestMapping
import com.gantsign.restrulz.restdsl.Response
import com.gantsign.restrulz.restdsl.ResponseWithBody
import com.gantsign.restrulz.restdsl.SimpleType
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StringRestriction
import com.gantsign.restrulz.restdsl.SuccessWithBodyStatus
import com.google.gson.stream.JsonWriter
import java.io.StringWriter
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

	private def writeProperties(BodyTypeRef param, JsonWriter writer) {
		writer.name("kind").value("body-param")
		writer.name("type-ref").value(param.ref.name)
	}

	private def writeProperties(PathParamRef param, JsonWriter writer) {
		writer.name("kind").value("path-param")
		writer.name("value-ref").value(param.ref.name)
	}

	private def writeObject(MethodParameter param, JsonWriter writer) {
		writer.beginObject

		switch (param) {
			PathParamRef: param.writeProperties(writer)
			BodyTypeRef: param.writeProperties(writer)
			default: throw new AssertionError("Unsupported parameter: " + param.class.name)
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

		writer.name("response-ref").value(handler.response.name)
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

		pathScope.path.forEach [ element |
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

	private def code(SuccessWithBodyStatus status) {
		return Integer.parseInt(status.getName().substring("HTTP_".length))
	}

	private def writeProperties(ResponseWithBody response, JsonWriter writer) {
		writer.name("status").value(response.status.code)
		writer.name("body-type-ref").value(response.body.name)
	}

	private def writeObject(Response response, JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(response.name)
		val detail = response.detail
		switch (detail) {
			ResponseWithBody: detail.writeProperties(writer)
			default: throw new AssertionError("Unsupported detail type: " + detail.class.name)
		}
		writer.endObject
	}

	private def writeObject(Property property, JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(property.name)
		writer.name("type-ref")
		if (property.type == null) {
			writer.value(defaultType)
		} else {
			writer.value(property.type.name)
		}
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

	private def writeProperties(StringRestriction restriction, JsonWriter writer) {
		writer.name("kind").value("string")
		writer.name("pattern").value(restriction.pattern)
		writer.name("min-length").value(restriction.length.start)
		writer.name("max-length").value(restriction.length.end)
	}

	private def writeObject(SimpleType simpleType, JsonWriter writer) {
		writer.beginObject
		writer.name("name").value(simpleType.name)
		val restriction = simpleType.restriction
		switch (restriction) {
			StringRestriction: restriction.writeProperties(writer)
			default: throw new AssertionError("Unsupported restriction type: " + restriction.class.name)
		}
		writer.endObject
	}

	private def usesDefaultType(Model model) {
		val propertyUsesDefaultType = model.classTypes.findFirst [ classType |
			classType.properties.findFirst [ property |
				property.type == null
			] != null
		] != null

		if (propertyUsesDefaultType) {
			return true
		}

		val pathParamUsesDefaultType = model.pathScopes.findFirst [ pathScope |
			pathScope.path.filter(PathParam).findFirst [ pathParam |
				pathParam.type == null
			] != null
		] != null

		return pathParamUsesDefaultType
	}

	private def hasSimpleType(Model model, String typeName) {
		model.simpleTypes.findFirst [ simpleType |
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

	private def toJson(Model model) {
		val buf = new StringWriter()
		val writer = new JsonWriter(buf);
		writer.indent = "  ";
		writer.beginObject

		writer.name("simple-types")
		writer.beginArray
		if (!model.hasSimpleType(defaultType) && model.usesDefaultType) {
			writeDefaultType(writer)
		}
		model.simpleTypes.forEach [ simpleType |
			simpleType.writeObject(writer)
		]
		writer.endArray

		writer.name("class-types")
		writer.beginArray
		model.classTypes.forEach [ classType |
			classType.writeObject(writer)
		]
		writer.endArray

		writer.name("responses")
		writer.beginArray
		model.responses.forEach [ response |
			response.writeObject(writer)
		]
		writer.endArray

		writer.name("path-scopes")
		writer.beginArray
		model.pathScopes.forEach [ pathScope |
			pathScope.writeObject(writer)
		]
		writer.endArray

		writer.endObject
		writer.close
		return buf.toString()
	}

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		for (model : resource.allContents.toIterable.filter(Model)) {
			fsa.generateFile('schema.json', model.toJson)
		}
	}

}
