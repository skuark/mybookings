require 'rails_helper'

module Mybookings
  describe Backend::ResourceTypesController do
    routes { Mybookings::Engine.routes }

    context 'when the user is not logged in' do
      describe 'on GET to index' do
        before { get :index }

        it { expect(response).to redirect_to(new_user_session_path) }
      end
    end

    context 'when the logged in user is not an admin' do
      describe 'on GET to index' do
        let(:user) { mybookings_users(:user) }

        before do
          sign_in(user)

          get :index
        end

        it { expect(response).to redirect_to(root_path) }
      end
    end

    context 'when the logged in user is an admin' do
      let(:admin) { mybookings_users(:admin) }

      before { sign_in(admin) }

      describe 'on GET to index' do
        let(:resource_types) { [] }

        before do
          allow(ResourceType).to receive(:all).and_return(resource_types)

          get :index
        end

        it { expect(assigns[:resource_types]).to eq(resource_types) }
        it { expect(response).to render_template(:index) }
      end

      describe 'on GET to new' do
        before { get :new }

        it { expect(assigns[:resource_type]).to be_a(ResourceType) }
        it { expect(response).to render_template(:new) }
      end

      describe 'on POST to create' do
        let(:resource_type_params) { { 'name' => '' } }
        let(:resource_type) { ResourceType.new(name: '') }

        context 'when the resource params are not valid' do
          before do
            allow(ResourceType).to receive(:new).with(resource_type_params).and_return(resource_type)
            allow(resource_type).to receive(:valid?).and_return(false)

            post :create, resource_type: resource_type_params
          end

          it { expect(response).to render_template(:new) }
        end

        context 'when the resource params are valid' do
          before do
            allow(ResourceType).to receive(:new).with(resource_type_params).and_return(resource_type)
            allow(resource_type).to receive(:valid?).and_return(true)
            allow(resource_type).to receive(:save!)

            post :create, resource_type: resource_type_params
          end

          it { expect(response).to redirect_to(backend_resource_types_path) }
        end
      end

      describe 'on GET to edit' do
        let(:resource_type_id) { '1' }
        let(:resource_type) { ResourceType.new }

        before do
          allow(ResourceType).to receive(:find).with(resource_type_id).and_return(resource_type)

          get :edit, id: resource_type_id
        end

        it { expect(response).to render_template(:edit) }
      end

      describe 'on PATCH to update' do
        let(:resource_type_id) { '1' }
        let(:resource_type) { ResourceType.new }
        let(:resource_type_params) { { 'name' => 'New name' } }

        context 'when the resource params are not valid' do
          before do
            allow(ResourceType).to receive(:find).with(resource_type_id).and_return(resource_type)
            allow(resource_type).to receive(:update_attributes).with(resource_type_params).and_return(false)

            patch :update, id: resource_type_id, resource_type: resource_type_params
          end

          it { expect(response).to render_template(:edit) }
        end

        context 'when the resource params are valid' do
          before do
            allow(ResourceType).to receive(:find).with(resource_type_id).and_return(resource_type)
            allow(resource_type).to receive(:update_attributes).with(resource_type_params).and_return(true)

            patch :update, id: resource_type_id, resource_type: resource_type_params
          end

          it { expect(response).to redirect_to(backend_resource_types_path) }
        end
      end
    end

  end
end
