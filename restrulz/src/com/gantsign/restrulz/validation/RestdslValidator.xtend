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
package com.gantsign.restrulz.validation

import com.gantsign.restrulz.restdsl.BodyTypeRef
import com.gantsign.restrulz.restdsl.ClassType
import com.gantsign.restrulz.restdsl.MethodParameter
import com.gantsign.restrulz.restdsl.PathElement
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.PathScope
import com.gantsign.restrulz.restdsl.Property
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.Response
import com.gantsign.restrulz.restdsl.RestdslPackage
import com.gantsign.restrulz.restdsl.SimpleType
import com.gantsign.restrulz.restdsl.Specification
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StringLengthRange
import com.gantsign.restrulz.restdsl.StringRestriction
import com.gantsign.restrulz.restdsl.Type
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException
import java.util.stream.StreamSupport
import javax.inject.Inject
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.impl.ResourceDescriptionsProvider
import org.eclipse.xtext.validation.Check

import static java.util.stream.Collectors.joining

/**
 * This class contains custom validation rules.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class RestdslValidator extends AbstractRestdslValidator {

	public static val INVALID_NAME_UPPER_CASE = 'invalidNameUpperCase'
	public static val INVALID_NAME_ILLEGAL_CHARS = 'invalidNameIllegalChars'
	public static val INVALID_NAME_HYPHEN_PREFIX = 'invalidNameHyphenPrefix'
	public static val INVALID_NAME_HYPHEN_SUFFIX = 'invalidNameHyphenSuffix'
	public static val INVALID_NAME_HYPHEN_RUN = 'invalidNameHyphenRun'
	public static val INVALID_NAME_DIGIT_POSITION = 'invalidNameDigitPosition'
	public static val INVALID_NAME_DUPLICATE = 'invalidNameDuplicate';
	public static val INVALID_STRING_TYPE_PATTERN = 'invalidStringTypePattern';
	public static val INVALID_STRING_TYPE_BLANK_PATTERN = 'invalidStringTypeBlankPattern';
	public static val INVALID_STRING_TYPE_MIN_LENGTH = 'invalidStringTypeMinLengh';
	public static val INVALID_STRING_TYPE_MAX_LENGTH = 'invalidStringTypeMaxLength';
	public static val INVALID_HANDLER_DUPLICATE_METHOD = 'invalidHandlerDuplicateMethod';
	public static val INVALID_PATH_DUPLICATE = 'invalidPathDuplicate';
	private static val UPPERCASE = Pattern.compile("\\p{Upper}")
	private static val SUPPORTED_CHARS = Pattern.compile("[\\p{Alnum}\\-]")
	private static val ILLEGAL_DIGIT_POSITION = Pattern.compile("[\\p{Digit}][\\p{Alpha}\\-]+$")

	@Inject extension ResourceDescriptionsProvider

	@Inject extension IContainer.Manager

	@Inject extension IQualifiedNameProvider

	private def hasUpperCase(String name) {
		return UPPERCASE.matcher(name).find
	}

	private def unsupportedChars(String name) {
		return SUPPORTED_CHARS.matcher(name).replaceAll("")
	}

	private def hasIllegalDigitPosition(String name) {
		return ILLEGAL_DIGIT_POSITION.matcher(name).find
	}

	private def hasRunOfHyphens(String name) {
		return name.contains("--")
	}

	def validateName(String name, EStructuralFeature feature) {
		if (name.hasUpperCase()) {
			error('name: must be lower case',
					feature,
					INVALID_NAME_UPPER_CASE)
		}
		val unsupportedChars = name.unsupportedChars
		if (!"".equals(unsupportedChars)) {
			error('name: contains illegal character(s): ' + unsupportedChars,
					feature,
					INVALID_NAME_ILLEGAL_CHARS)
		}
		if (name.startsWith("-")) {
			error('name: must start with a letter',
					feature,
					INVALID_NAME_HYPHEN_PREFIX)
		}
		if (name.endsWith("-")) {
			error('name: must end with a letter or a digit',
					feature,
					INVALID_NAME_HYPHEN_SUFFIX)
		}
		if (name.hasRunOfHyphens) {
			error('name: hyphens must not be immediately followed by another hyphen',
					feature,
					INVALID_NAME_HYPHEN_RUN)
		}
		if (name.hasIllegalDigitPosition) {
			error('name: numeric digits are only permitted as a suffix to the name',
					feature,
					INVALID_NAME_DIGIT_POSITION)
		}
	}

	@Check
	def validateSpecificationName(Specification spec) {
		validateName(spec.name, RestdslPackage.Literals.SPECIFICATION__NAME)
	}

	def validateTypeName(String name) {
		validateName(name, RestdslPackage.Literals.TYPE__NAME)
	}

	@Check
	def validateSimpleTypeName(SimpleType type) {
		validateTypeName(type.name)
	}

	@Check
	def validateClassTypeName(ClassType type) {
		validateTypeName(type.name)
	}

	@Check
	def validatePropertyName(Property property) {
		validateName(property.name, RestdslPackage.Literals.PROPERTY__NAME)
	}

	@Check
	def validateResponseName(Response response) {
		validateName(response.name, RestdslPackage.Literals.RESPONSE__NAME)
	}

	@Check
	def validatePathScopeName(PathScope pathScope) {
		validateName(pathScope.name, RestdslPackage.Literals.PATH_SCOPE__NAME)
	}

	@Check
	def validatePathParamName(PathParam pathParam) {
		validateName(pathParam.name, RestdslPackage.Literals.PATH_PARAM__NAME)
	}

	@Check
	def validateRequestHandelerName(RequestHandler handler) {
		validateName(handler.name, RestdslPackage.Literals.REQUEST_HANDLER__NAME)
	}

	private def permitsBlank(Pattern pattern) {
		return pattern.matcher(" ").matches || pattern.matcher("\t").matches
	}

	@Check
	def validateStringPattern(StringRestriction stringRestriction) {
		val patternString = stringRestriction.pattern
		val pattern = try {
			Pattern.compile(patternString)
		} catch (PatternSyntaxException e) {
			error('pattern: not a valid regular expression',
					RestdslPackage.Literals.STRING_RESTRICTION__PATTERN,
					INVALID_STRING_TYPE_PATTERN)
			return;
		}
		if (pattern.permitsBlank) {
			error('pattern: must not permit blank strings',
					RestdslPackage.Literals.STRING_RESTRICTION__PATTERN,
					INVALID_STRING_TYPE_BLANK_PATTERN)
		}
	}

	@Check
	def validateStringLengthRange(StringLengthRange range) {
		if (range.start < 1) {
			error('min-length: must be at least 1',
					RestdslPackage.Literals.STRING_LENGTH_RANGE__START,
					INVALID_STRING_TYPE_MIN_LENGTH)
		}
		if (range.end < range.start) {
			error('max-length: must be greater than or equal to min-length',
					RestdslPackage.Literals.STRING_LENGTH_RANGE__END,
					INVALID_STRING_TYPE_MAX_LENGTH)
		}
	}

	def streamVisibleExportedObjectsByType(EObject object, EClass type) {
		val resourceDescriptions = object.eResource.resourceDescriptions
		val resourceDescription = resourceDescriptions.getResourceDescription(object.eResource.URI)
		return resourceDescription.getVisibleContainers(resourceDescriptions)
				.stream
				.map[it.getExportedObjectsByType(type)]
				.flatMap[StreamSupport.stream(it.spliterator, false)]
	}

	def isNameUnique(EObject object, EClass type) {
		val qualifiedName = object.fullyQualifiedName
		return object.streamVisibleExportedObjectsByType(type)
				.map[it.qualifiedName]
				.filter[qualifiedName.equals(it)]
				.limit(2)
				.count < 2
	}

	@Check
	def validateTypeNameUnique(Type type) {
		if (!type.isNameUnique(RestdslPackage.Literals.TYPE)) {
			error("name: type/class names must be unique",
					RestdslPackage.Literals.TYPE__NAME, INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validatePropertyNameUnique(Property property) {
		if (!property.isNameUnique(RestdslPackage.Literals.PROPERTY)) {
			error("name: property names must be unique",
					RestdslPackage.Literals.PROPERTY__NAME, INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validateResponseNameUnique(Response response) {
		if (!response.isNameUnique(RestdslPackage.Literals.RESPONSE)) {
			error("name: response names must be unique",
					RestdslPackage.Literals.RESPONSE__NAME, INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validatePathScopeNameUnique(PathScope pathScope) {
		if (!pathScope.isNameUnique(RestdslPackage.Literals.PATH_SCOPE)) {
			error("name: path names must be unique",
					RestdslPackage.Literals.PATH_SCOPE__NAME, INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validatePathParamNameUnique(PathParam pathParam) {
		if (!pathParam.isNameUnique(RestdslPackage.Literals.PATH_PARAM)) {
			error("name: path parameter names must be unique",
					RestdslPackage.Literals.PATH_PARAM__NAME, INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validateRequestHandlerNameUnique(RequestHandler requestHandler) {
		if (!requestHandler.isNameUnique(RestdslPackage.Literals.REQUEST_HANDLER)) {
			error("name: request handler names must be unique",
					RestdslPackage.Literals.REQUEST_HANDLER__NAME, INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validateRequestHandlerMethodUnique(RequestHandler requestHandler) {
		val method = requestHandler.method

		val pathScope = EcoreUtil2.getContainerOfType(requestHandler, PathScope)

		val hasDuplicates = EcoreUtil2.getAllContents(pathScope.mappings)
				.filter(RequestHandler)
				.map[it.method]
				.filter[method.equals(it)]
				.toList
				.size >= 2

		if (hasDuplicates) {
			error("method: each HTTP method can only have one handler",
					RestdslPackage.Literals.REQUEST_HANDLER__METHOD,
					INVALID_HANDLER_DUPLICATE_METHOD)
		}
	}

	private def getName(MethodParameter param) {
		return if (param instanceof PathParamRef) {
			param.ref.name
		} else if (param instanceof BodyTypeRef) {
			param.ref.name
		} else {
			throw new AssertionError("Unsupported parameter type: " + param.class.name)
		}
	}

	private def isNameUnique(MethodParameter param) {
		val name = param.name
		val requestHandler = EcoreUtil2.getContainerOfType(param, RequestHandler)

		val parameters = requestHandler.parameters
		return parameters
				.stream
				.map[it.name]
				.filter[it.equals(name)]
				.limit(2)
				.count < 2
	}

	@Check
	def validateHandlerParametersUnique(PathParamRef param) {
		if (!param.isNameUnique) {
			error("name: parameter name must be unique",
					RestdslPackage.Literals.PATH_PARAM_REF__REF,
					INVALID_NAME_DUPLICATE)
		}
	}

	@Check
	def validateHandlerParametersUnique(BodyTypeRef param) {
		if (!param.isNameUnique) {
			error("name: parameter name must be unique",
					RestdslPackage.Literals.BODY_TYPE_REF__REF,
					INVALID_NAME_DUPLICATE)
		}
	}

	private def getPathString(PathElement element) {
		return if (element instanceof StaticPathElement) {
			element.value
		} else if (element instanceof PathParam) {
			""
		} else {
			throw new AssertionError("Unsupported path element: " + element.class.name)
		}
	}

	private def getPathString(PathScope pathScope) {
		return pathScope.path.elements
				.stream
				.map[it.pathString]
				.collect(joining("/", "/", ""))
	}

	@Check
	def validatePathUnique(PathScope pathScope) {
		val path = pathScope.pathString
		val spec = EcoreUtil2.getContainerOfType(pathScope, Specification)

		val hasDuplicates = spec.pathScopes
				.stream
				.map[it.pathString]
				.filter[path.equals(it)]
				.limit(2)
				.count >= 2

		if (hasDuplicates) {
			error("path must be unique",
					RestdslPackage.Literals.PATH_SCOPE__PATH,
					INVALID_PATH_DUPLICATE)
		}
	}
}
