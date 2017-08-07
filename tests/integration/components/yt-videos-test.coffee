import { test, moduleForComponent } from 'ember-qunit'
import hbs from 'htmlbars-inline-precompile'

moduleForComponent 'yt-videos', 'Integration | Component | yt videos', {
  integration: true
}

test 'it renders', (assert) ->
  assert.expect 2

  # Set any properties with @set 'myProperty', 'value'
  # Handle any actions with @on 'myAction', (val) ->

  @render hbs """{{yt-videos}}"""

  assert.equal @$().text().trim(), ''

  # Template block usage:
  @render hbs """
    {{#yt-videos}}
      template block text
    {{/yt-videos}}
  """

  assert.equal @$().text().trim(), 'template block text'
