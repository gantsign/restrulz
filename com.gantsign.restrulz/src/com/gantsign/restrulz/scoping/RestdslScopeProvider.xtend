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
package com.gantsign.restrulz.scoping

import com.gantsign.restrulz.restdsl.PathParam
import com.gantsign.restrulz.restdsl.PathParamRef
import com.gantsign.restrulz.restdsl.PathScope
import com.gantsign.restrulz.restdsl.RestdslPackage
import com.gantsign.restrulz.restdsl.SubPathScope
import java.util.ArrayList
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes

/**
 * This class contains custom scoping description.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class RestdslScopeProvider extends AbstractRestdslScopeProvider {

	override getScope(EObject context, EReference reference) {
		if (context instanceof PathParamRef
				&& reference == RestdslPackage.Literals.PATH_PARAM_REF__REF) {

			val candidatesPerScope = new ArrayList<List<PathParam>>()

			var subPathScope = EcoreUtil2.getContainerOfType(context, SubPathScope)
			while(subPathScope != null) {
				candidatesPerScope.add(
					subPathScope.path.elements
						.filter(PathParam)
						.toList)

				subPathScope = EcoreUtil2.getContainerOfType(subPathScope.eContainer, SubPathScope)
			}

			val pathScope = EcoreUtil2.getContainerOfType(context, PathScope)
			candidatesPerScope.add(
				pathScope.path.elements
					.filter(PathParam)
					.toList)

			var scope = IScope.NULLSCOPE
			for (candidates : candidatesPerScope.reverse) {
				scope = Scopes.scopeFor(candidates, scope)
			}

			return scope
		}

		return super.getScope(context, reference)
	}

}
