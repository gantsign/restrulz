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
package com.gantsign.restrulz.tests

import com.gantsign.restrulz.restdsl.Model
import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.junit.Assert
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(XtextRunner)
@InjectWith(RestdslInjectorProvider)
class RestdslParsingTest{

	@Inject
	ParseHelper<Model> parseHelper

	@Test
	def void parseStringType() {
		val result = parseHelper.parse('''
			type Name : string ^[\p{Alpha}\']+$ length [1..100]
		''')
		Assert.assertNotNull(result)
	}

	@Test
	def void parseClassType() {
		val result = parseHelper.parse('''
			class Person {
				firstName

				lastName
			}
		''')
		Assert.assertNotNull(result)
	}

	@Test
	def void parseClassTypeRestrictedProperties() {
		val result = parseHelper.parse('''
			type Name : string ^[\p{Alpha}\']+$ length [1..100]

			class Person {
				firstName : Name

				lastName : Name
			}
		''')
		Assert.assertNotNull(result)
	}

	@Test
	def void parsePathScope() {
		val result = parseHelper.parse('''
			path /person/{id} : PersonWs {

			}
		''')
		Assert.assertNotNull(result)
	}

	def void parsePathScopeRestrictedId() {
		val result = parseHelper.parse('''
			type Uuid : string ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ length [36..36]

			path /person/{id : Uuid} : PersonWs {

			}
		''')
		Assert.assertNotNull(result)
	}
}
