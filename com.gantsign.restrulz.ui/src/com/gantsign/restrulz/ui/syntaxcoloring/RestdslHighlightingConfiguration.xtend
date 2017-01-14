package com.gantsign.restrulz.ui.syntaxcoloring

import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor
import org.eclipse.xtext.ui.editor.utils.TextStyle

import static com.gantsign.restrulz.ui.syntaxcoloring.RestdslHighlightingStyles.DOCUMENTATION_ID

class RestdslHighlightingConfiguration extends DefaultHighlightingConfiguration {

	@Override
	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor);
		acceptor.acceptDefaultHighlighting(DOCUMENTATION_ID, "Documentation", documentationTextStyle());
	}

	def TextStyle documentationTextStyle() {
		val textStyle = defaultTextStyle().copy;
		textStyle.setColor(new RGB(100, 100, 100));
		return textStyle;
	}
}
