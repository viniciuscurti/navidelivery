require 'rails_helper'

class DummyController < ApplicationController
  include TurboNativeDetectable
  def index
    render plain: @turbo_native ? 'native' : 'web'
  end
end

RSpec.describe DummyController, type: :controller do
  controller(DummyController) do
    def index
      super
    end
  end

  it 'detecta Turbo Native via User-Agent' do
    request.headers['User-Agent'] = 'Turbo Native iOS'
    get :index
    expect(response.body).to eq('native')
  end

  it 'detecta Turbo Native via X-Turbo-Native header' do
    request.headers['X-Turbo-Native'] = '1'
    get :index
    expect(response.body).to eq('native')
  end

  it 'detecta web quando não é Turbo Native' do
    request.headers['User-Agent'] = 'Mozilla/5.0'
    get :index
    expect(response.body).to eq('web')
  end
end

