/*
 * Copyright 2016-2017 GantSign Ltd. All Rights Reserved.
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

import com.gantsign.restrulz.restdsl.ClassType
import com.gantsign.restrulz.restdsl.IntegerType
import com.gantsign.restrulz.restdsl.MethodParameter
import com.gantsign.restrulz.restdsl.Path
import com.gantsign.restrulz.restdsl.PathElement
import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathScope
import com.gantsign.restrulz.restdsl.Property
import com.gantsign.restrulz.restdsl.RequestHandler
import com.gantsign.restrulz.restdsl.Response
import com.gantsign.restrulz.restdsl.ResponseOptionalBody
import com.gantsign.restrulz.restdsl.ResponseRef
import com.gantsign.restrulz.restdsl.ResponseWithBody
import com.gantsign.restrulz.restdsl.ResponseWithoutBody
import com.gantsign.restrulz.restdsl.RestdslPackage
import com.gantsign.restrulz.restdsl.SimpleType
import com.gantsign.restrulz.restdsl.Specification
import com.gantsign.restrulz.restdsl.StaticPathElement
import com.gantsign.restrulz.restdsl.StatusRequiresBody
import com.gantsign.restrulz.restdsl.StringType
import com.gantsign.restrulz.restdsl.SubPathScope
import com.gantsign.restrulz.restdsl.Type
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException
import java.util.stream.StreamSupport
import javax.inject.Inject
import org.eclipse.emf.common.util.Enumerator
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

	public static val BAD_HANDLER_MISSING_ERROR_RESPONSE = 'badHandlerMissingErrorResponse'
	public static val INVALID_NAME_UPPER_CASE = 'invalidNameUpperCase'
	public static val INVALID_NAME_ILLEGAL_CHARS = 'invalidNameIllegalChars'
	public static val INVALID_NAME_HYPHEN_PREFIX = 'invalidNameHyphenPrefix'
	public static val INVALID_NAME_HYPHEN_SUFFIX = 'invalidNameHyphenSuffix'
	public static val INVALID_NAME_HYPHEN_RUN = 'invalidNameHyphenRun'
	public static val INVALID_NAME_DIGIT_POSITION = 'invalidNameDigitPosition'
	public static val INVALID_NAME_DUPLICATE = 'invalidNameDuplicate'
	public static val INVALID_STRING_TYPE_PATTERN = 'invalidStringTypePattern'
	public static val INVALID_STRING_TYPE_MIN_LENGTH = 'invalidStringTypeMinLength'
	public static val INVALID_STRING_TYPE_MAX_LENGTH = 'invalidStringTypeMaxLength'
	public static val INVALID_HANDLER_DUPLICATE_METHOD = 'invalidHandlerDuplicateMethod'
	public static val INVALID_HANDLER_DUPLICATE_RESPONSE = 'invalidHandlerDuplicateResponse'
	public static val INVALID_HANDLER_DUPLICATE_RESPONSE_STATUS = 'invalidHandlerDuplicateResponseStatus'
	public static val INVALID_PATH_DUPLICATE = 'invalidPathDuplicate'
	public static val INVALID_SUB_PATH_DUPLICATE = 'invalidSubPathDuplicate'
	public static val INVALID_INTEGER_RANGE = 'invalidIntegerRange'
	public static val INVALID_PROPERTY_NULL = 'invalidPropertyNull'
	public static val INVALID_PROPERTY_EMPTY = 'invalidPropertyEmpty'
	public static val INVALID_SPECIFICATION_NAME_FILE_MISMATCH = 'invalidSpecificationNameFileMismatch'
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

	private def validateName(String name, EStructuralFeature feature) {
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

	private def validateTypeName(String name) {
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

	@Check
	def validateMethodParameterName(MethodParameter parameter) {
		validateName(parameter.name, RestdslPackage.Literals.METHOD_PARAMETER__NAME)
	}

	@Check
	def validateSpecificationNameMatchesFile(Specification spec) {
		val srcFileName = spec.eResource.URI.lastSegment
		val withoutExtension = srcFileName.toString.replaceFirst("\\.rrdl$", "")
		if (!spec.name.equals(withoutExtension)) {
			error("name: must match file name (i.e. " + withoutExtension + ")",
					RestdslPackage.Literals.SPECIFICATION__NAME,
					INVALID_SPECIFICATION_NAME_FILE_MISMATCH)
		}
	}

	@Check
	def validateStringPattern(StringType stringType) {
		val patternString = stringType.pattern
		try {
			Pattern.compile(patternString)
		} catch (PatternSyntaxException e) {
			error('pattern: not a valid regular expression',
					RestdslPackage.Literals.STRING_TYPE__PATTERN,
					INVALID_STRING_TYPE_PATTERN)
			return
		}
	}

	@Check
	def validateStringLengthRange(StringType stringType) {
		if (stringType.minLength < 1) {
			error('min-length: must be at least 1',
					RestdslPackage.Literals.STRING_TYPE__MIN_LENGTH,
					INVALID_STRING_TYPE_MIN_LENGTH)
		}
		if (stringType.maxLength < stringType.minLength) {
			error('max-length: must be greater than or equal to min-length',
					RestdslPackage.Literals.STRING_TYPE__MAX_LENGTH,
					INVALID_STRING_TYPE_MAX_LENGTH)
		}
	}

	@Check
	def validateIntegerTypeRange(IntegerType integerType) {
		if (integerType.maximum < integerType.minimum) {
			error('maximum: must be greater than or equal to minimum',
					RestdslPackage.Literals.INTEGER_TYPE__MAXIMUM,
					INVALID_INTEGER_RANGE)
		}
	}

	private def streamVisibleExportedObjectsByType(EObject object, EClass type) {
		val resourceDescriptions = object.eResource.resourceDescriptions
		val resourceDescription = resourceDescriptions.getResourceDescription(object.eResource.URI)
		return resourceDescription.getVisibleContainers(resourceDescriptions)
				.stream
				.map[it.getExportedObjectsByType(type)]
				.flatMap[StreamSupport.stream(it.spliterator, false)]
	}

	private def isNameUnique(EObject object, EClass type) {
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
		var hasDuplicate = false

		// search parents
		var subPathScope = EcoreUtil2.getContainerOfType(pathParam, SubPathScope)
		while(!hasDuplicate && subPathScope != null) {
			hasDuplicate = subPathScope.path.elements
					.filter(PathParam)
					.filter[it != pathParam]
					.filter[it.name == pathParam.name]
					.toList
					.size > 0

			subPathScope = EcoreUtil2.getContainerOfType(subPathScope.eContainer, SubPathScope)
		}

		if (!hasDuplicate) {
			val pathScope = EcoreUtil2.getContainerOfType(pathParam, PathScope)
			hasDuplicate = pathScope.path.elements
					.filter(PathParam)
					.filter[it != pathParam]
					.filter[it.name == pathParam.name]
					.toList
					.size > 0
		}

		if (!hasDuplicate) {
			// search children
			val parent = EcoreUtil2.getContainerOfType(pathParam, SubPathScope)

			val subPathParams = if (parent != null) {
				EcoreUtil2.getAllContentsOfType(parent, PathParam)
			} else {
				val pathScope = EcoreUtil2.getContainerOfType(pathParam, PathScope)
				EcoreUtil2.getAllContentsOfType(pathScope, PathParam)
			}

			hasDuplicate = subPathParams
					.filter[it != pathParam]
					.filter[it.name == pathParam.name]
					.toList
					.size > 0
		}

		if (hasDuplicate) {
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

		val subPathScope = EcoreUtil2.getContainerOfType(requestHandler, SubPathScope)

		val hasDuplicates = if (subPathScope != null) {
			subPathScope.mappings
					.filter(RequestHandler)
					.filter[it.method == method]
					.toList
					.size >= 2
		} else {
			val pathScope = EcoreUtil2.getContainerOfType(requestHandler, PathScope)

			pathScope.mappings
					.filter(RequestHandler)
					.filter[it.method == method]
					.toList
					.size >= 2
		}

		if (hasDuplicates) {
			error("method: each HTTP method can only have one handler for a given path",
					RestdslPackage.Literals.REQUEST_HANDLER__METHOD,
					INVALID_HANDLER_DUPLICATE_METHOD)
		}
	}

	private def Enumerator getStatus(Response response) {
		val responseDetail = response.detail
		return switch (responseDetail) {
			ResponseWithBody: responseDetail.status
			ResponseOptionalBody: responseDetail.status
			ResponseWithoutBody: responseDetail.status
			default: throw new IllegalArgumentException('''Unexpected type «responseDetail.class.name»''')
		}
	}

	@Check
	def validateRequestHandlerResponsesDuplicates(ResponseRef responseRef) {
		val name = responseRef.ref.name

		val handler = EcoreUtil2.getContainerOfType(responseRef, RequestHandler)

		val hasDuplicates = handler.responses
				.map[it.ref.name]
				.filter[name == it]
				.toList
				.size >= 2

		if (hasDuplicates) {
			error("duplicate response mapping",
					RestdslPackage.Literals.RESPONSE_REF__REF,
					INVALID_HANDLER_DUPLICATE_RESPONSE)
		}
	}

	@Check
	def validateRequestHandlerResponsesDuplicateStatus(ResponseRef responseRef) {
		val name = responseRef.ref.name

		val handler = EcoreUtil2.getContainerOfType(responseRef, RequestHandler)

		val status = responseRef.ref.status

		val statusLabel = status.literal
		val statusCode = status.name.substring("HTTP_".length)

		val hasStatusDuplicates = handler.responses
				.map[it.ref]
				.filter[it.name != name]
				.filter[it.status == status]
				.toList
				.size > 0

		if (hasStatusDuplicates) {
			error('''duplicate mapping for HTTP status code «statusCode» («statusLabel»)''',
					RestdslPackage.Literals.RESPONSE_REF__REF,
					INVALID_HANDLER_DUPLICATE_RESPONSE_STATUS)
		}
	}

	@Check
	def validateRequestHandlerErrorMapping(RequestHandler handler) {

		if (handler.responses.isEmpty) {
			return;
		}

		val hasErrorMapping = handler.responses
				.filter[it.ref.status == StatusRequiresBody.HTTP_500]
				.toList
				.size > 0

		if (!hasErrorMapping) {
			warning("no mapping for HTTP 500 (internal-server-error)",
					RestdslPackage.Literals.REQUEST_HANDLER__RESPONSES,
					RestdslValidator.BAD_HANDLER_MISSING_ERROR_RESPONSE)
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
	def validateHandlerParametersUnique(MethodParameter param) {
		if (!param.isNameUnique) {
			error("name: parameter name must be unique",
					RestdslPackage.Literals.METHOD_PARAMETER__NAME,
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

	private def getPathString(Path path) {
		return path.elements
				.stream
				.map[it.pathString]
				.collect(joining("/", "/", ""))
	}

	private def getPathString(PathScope pathScope) {
		return pathScope.path.pathString
	}

	private def getPathString(SubPathScope subPathScope) {

		var pathString = subPathScope.path.pathString

		var parentScope = EcoreUtil2.getContainerOfType(subPathScope.eContainer, SubPathScope)

		while (parentScope != null) {
			pathString = parentScope.path.pathString + pathString

			parentScope = EcoreUtil2.getContainerOfType(parentScope.eContainer, SubPathScope)
		}

		var rootScope = EcoreUtil2.getContainerOfType(subPathScope, PathScope)

		return rootScope.pathString + pathString
	}

	@Check
	def validatePathUnique(PathScope pathScope) {
		val path = pathScope.pathString

		val spec = EcoreUtil2.getContainerOfType(pathScope, Specification)

		var hasDuplicates = spec.pathScopes
				.stream
				.filter[it.pathString == path]
				.limit(2)
				.count >= 2

		if (!hasDuplicates) {
			val subPathScopes = EcoreUtil2.getAllContentsOfType(spec, SubPathScope)

			hasDuplicates = subPathScopes
					.stream
					.filter[it.pathString == path]
					.limit(2)
					.count > 0

		}

		if (hasDuplicates) {
			error("path must be unique",
					RestdslPackage.Literals.PATH_SCOPE__PATH,
					INVALID_PATH_DUPLICATE)
		}
	}

	@Check
	def validatePathUnique(SubPathScope subPathScope) {
		val path = subPathScope.pathString

		val spec = EcoreUtil2.getContainerOfType(subPathScope, Specification)

		val subPathScopes = EcoreUtil2.getAllContentsOfType(spec, SubPathScope)

		var hasDuplicates = subPathScopes
				.stream
				.filter[it.pathString == path]
				.limit(2)
				.count >= 2

		if (!hasDuplicates) {
			hasDuplicates = spec.pathScopes
					.stream
					.filter[it.pathString == path]
					.limit(1)
					.count > 0
		}

		if (hasDuplicates) {
			error("path must be unique",
					RestdslPackage.Literals.SUB_PATH_SCOPE__PATH,
					INVALID_SUB_PATH_DUPLICATE)
		}
	}

	@Check
	def validatePropertyModifiers(Property property) {
		val type = property.type
		if (property.isAllowNull) {
			if (!(type instanceof IntegerType) && !(type instanceof ClassType)) {
				error("only integer and class types are allowed to be null",
						RestdslPackage.Literals.PROPERTY__ALLOW_NULL,
						INVALID_PROPERTY_NULL)
			}

		} else if (property.isAllowEmpty) {
			if (!(type instanceof StringType)) {
				error("only string types are allowed to be empty",
						RestdslPackage.Literals.PROPERTY__ALLOW_EMPTY,
						INVALID_PROPERTY_EMPTY)
			}
		}
	}
}
