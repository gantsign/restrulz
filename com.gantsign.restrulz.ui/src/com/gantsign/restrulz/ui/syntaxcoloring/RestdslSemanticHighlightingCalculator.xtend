package com.gantsign.restrulz.ui.syntaxcoloring

import com.gantsign.restrulz.restdsl.SpecificationDoc
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.ide.editor.syntaxcoloring.DefaultSemanticHighlightingCalculator
import org.eclipse.xtext.ide.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.nodemodel.ILeafNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.util.CancelIndicator

import static com.gantsign.restrulz.ui.syntaxcoloring.RestdslHighlightingStyles.DOCUMENTATION_ID

class RestdslSemanticHighlightingCalculator extends DefaultSemanticHighlightingCalculator {

	override protected highlightElement(EObject object, IHighlightedPositionAcceptor acceptor,
			CancelIndicator cancelIndicator) {
			
		if (object instanceof SpecificationDoc) {
			val node = NodeModelUtils.findActualNodeFor(object)
			for (ILeafNode leafNode : node.leafNodes) {
				if (!leafNode.isHidden && leafNode.grammarElement instanceof Keyword) {
					highlightNode(acceptor, leafNode, DOCUMENTATION_ID) 
				}
			}
		}
		return false
	}
}
