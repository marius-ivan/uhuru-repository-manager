#
#    The dashboard landing page for the admin user
#

module Uhuru
  module RepositoryManager
    module Admin
      def self.registered(urm)

        # the route that redirects to the admin dashboard page
        #
        urm.get DASHBOARD do
          unless logged_in_as_admin?
            redirect NOT_ADMIN
          end
          mirrors = Uhuru::RepositoryManager::Model::Mirrors.get_dashboard_mirrors
          user_sys = Uhuru::RepositoryManager::Model::Users.get_users(:username => session[:username]).first.user_sys
          home_user = File.join($config[:path_home_user], user_sys)

          render_erb do
            template :'dashboard'
            layout :'layouts/layout'
            var :mirrors, mirrors
            var :user_sys, user_sys
            var :home_user, home_user
          end
        end

        urm.get ADMIN_KEYS do
          unless logged_in_as_admin?
            redirect NOT_ADMIN
          end

          user_id = Uhuru::RepositoryManager::Model::Users.get_users(:username => session[:username]).first.id
          access_keys = Uhuru::RepositoryManager::Model::AccessKeys.get_access_keys_by_user(user_id)
          render_erb do
            template :'keys'
            layout :'layouts/layout'
            var :access_keys, access_keys
          end
        end

        # Add and remove access keys for the logged in admin user
        #
        urm.post ADMIN_ADD_KEY do
          unless logged_in_as_admin?
            redirect NOT_ADMIN
          end
          user = Uhuru::RepositoryManager::Model::Users.get_users(:username => session[:username]).first

          begin
            Uhuru::RepositoryManager::Model::AccessKeys.create(params[:key].sub(/\s+\Z/, ""), params[:name], user)
          rescue Exception => ex
            error_message = Uhuru::RepositoryManager::Error.new('Access key error: ', ex.message)
            $logger.error("Add access key : #{ex.message} - #{ex.backtrace}")
          end

          access_keys = Uhuru::RepositoryManager::Model::AccessKeys.get_access_keys_by_user(user.id)
          render_erb do
            template :'keys'
            layout :'layouts/layout'
            var :access_keys, access_keys
            var :error_message, error_message || nil
          end
        end

        urm.post ADMIN_DELETE_KEY do
          unless logged_in_as_admin?
            redirect NOT_ADMIN
          end
          user_id = Uhuru::RepositoryManager::Model::Users.get_users(:username => session[:username]).first.id

          begin
            key = Uhuru::RepositoryManager::Model::AccessKeys.get_access_keys_by_user(user_id).find{|key| key.value == params[:key]}
            Uhuru::RepositoryManager::Model::AccessKeys.delete(key)
          rescue Exception => ex
            error_message = Uhuru::RepositoryManager::Error.new('Access key error: ', ex.message)
            $logger.error("Delete access key : #{ex.message} - #{ex.backtrace}")
          end

          access_keys = Uhuru::RepositoryManager::Model::AccessKeys.get_access_keys_by_user(user_id)
          render_erb do
            template :'keys'
            layout :'layouts/layout'
            var :access_keys, access_keys
            var :error_message, error_message || nil
          end
        end
      end
    end
  end
end
