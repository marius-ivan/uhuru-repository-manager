#
#    Account settings methods
#

module Uhuru
  module RepositoryManager
    module AccountSettings
      def self.registered(urm)
        # user and admin account settings page
        #
        urm.get ACCOUNT_SETTINGS do
          unless logged_in?
            redirect NOT_LOGGED_IN
          end

          user = Uhuru::RepositoryManager::Model::Users.get_users(:username => session[:username]).first
          countries_file = File.expand_path("../../../config/countries.txt", __FILE__)
          countries = File.open(countries_file, "rb").read.split(';')

          render_erb do
            template :'account_settings'
            layout :'layouts/layout'
            var :user, user
            var :countries, countries
          end
        end

        # Post method for changing the user data and metadata(the user that is currently logged in)
        #
        urm.post ACCOUNT_SETTINGS do
          unless logged_in?
            redirect NOT_LOGGED_IN
          end

          user = Uhuru::RepositoryManager::Model::Users.get_users(:username => session[:username]).first
          countries_file = File.expand_path("../../../config/countries.txt", __FILE__)
          countries = File.open(countries_file, "rb").read.split(';')

          hash = {
              :first_name => params[:first_name],
              :last_name => params[:last_name],
              :organization => params[:organization],
              :job_title => params[:job_title],
              :country => params[:country],
              :city => params[:city],
              :address => params[:address],
              :phone => params[:phone]
          }

          begin
            # sanitize the first and last name, pop error if one of them are nill
            unless /[a-zA-Z\-'\s]+/.match(params[:first_name]) && /[a-zA-Z\-'\s]+/.match(params[:last_name])
              raise Uhuru::RepositoryManager::Error.new('Account settings error', 'Please type a valid first name and last name.')
            end

            if params[:organization] == ''
              raise Uhuru::RepositoryManager::Error.new('Account settings error', 'Organization can not be blank.')
            elsif params[:job_title] == ''
              raise Uhuru::RepositoryManager::Error.new('Account settings error', 'Job title can not be blank.')
            end

            Uhuru::RepositoryManager::Model::Users.update(user, hash)
          rescue Exception => ex
            error_message = Uhuru::RepositoryManager::Error.new('Change account data: ', ex.message)
            $logger.error("Change account data : #{ex.message} - #{ex.backtrace}")
          end

          begin
            if params[:password] != params[:confirm_password]
              raise Uhuru::RepositoryManager::Error.new('Change password', 'Your password does not match with the confirm password.')
            else
              if password_length(params[:password])
                Uhuru::RepositoryManager::HtpasswdHandler.create_password(session[:username], params[:password])
              else
                raise Uhuru::RepositoryManager::Error.new('Change password', "User password needs to be between #{PASSWORD_MINIMUM_LENGTH} and #{PASSWORD_MAXIMUM_LENGTH} characters.")
              end
            end

          rescue Exception => ex
            error_message = Uhuru::RepositoryManager::Error.new('Change account data: ', ex.message)
            $logger.error("Change account data : #{ex.message} - #{ex.backtrace}")
          end

          render_erb do
            template :'account_settings'
            layout :'layouts/layout'
            var :user, user
            var :countries, countries
            var :error_message, error_message || nil
          end
        end

      end
    end
  end
end