module ASModel
  # Code that keeps the records of different repositories isolated and hiding suppressed records.
  module ModelScoping

    def self.included(base)
      base.extend(ClassMethods)
    end


    def uri
      # Bleh!
      self.class.uri_for(self.class.my_jsonmodel.record_type, self.id)
    end


    module ClassMethods

      def enable_suppression
        @suppressible = true
      end


      def enforce_suppression?
        RequestContext.get(:enforce_suppression)
      end


      def suppressible?
        @suppressible
      end

      def set_model_scope(value)
        if ![:repository, :global].include?(value)
          raise "Failure for #{self}: Model scope must be set as :repository or :global"
        end

        if value == :repository
          model = self
          orig_ds = self.dataset.clone

          # Provide a new '.this_repo' method on this model class that only
          # returns records that belong to the current repository.
          def_dataset_method(:this_repo) do
            filter = {:repo_id => model.active_repository}

            if model.suppressible? && model.enforce_suppression?
              filter[:suppressed] = 0
            end

            orig_ds.filter(filter)
          end


          # And another that will return records from any repository
          def_dataset_method(:any_repo) do
            if model.suppressible? && model.enforce_suppression?
              orig_ds.filter(:suppressed => 0)
            else
              orig_ds
            end
          end


          # Replace the default row_proc with one that fetches the request row,
          # but blows up if that row isn't from the currently active repository.
          orig_row_proc = self.dataset.row_proc
          self.dataset.row_proc = proc do |row|
            if row.has_key?(:repo_id) && row[:repo_id] != model.active_repository
              raise ("ASSERTION FAILED: #{row.inspect} has a repo_id of " +
                     "#{row[:repo_id]} but the active repository is #{model.active_repository}")
            end

            orig_row_proc.call(row)
          end

        end

        @model_scope = value
      end


      def model_scope(noerror = false)
        @model_scope or
          if noerror
            nil
          else
            raise "set_model_scope definition missing for model #{self}"
          end
      end


      # Like JSONModel.parse_reference, but enforce repository restrictions
      def parse_reference(uri, opts)
        ref = JSONModel.parse_reference(uri, opts)

        return nil if !ref

        # If the current model is repository scoped, and the reference is a
        # repository-scoped URI, make sure they're talking about the same
        # repository.
        if self.model_scope == :repository && ref[:repository] && ref[:repository] != JSONModel(:repository).uri_for(active_repository)
          raise ReferenceError.new("Invalid URI reference for this (#{active_repository}) repo: '#{uri}'")
        end

        ref
      end


      def active_repository
        repo = RequestContext.get(:repo_id)

        if model_scope == :repository and repo.nil?
          raise "Missing repo_id for request!"
        end

        repo
      end


      def uri_for(jsonmodel, id, opts = {})
        JSONModel(jsonmodel).uri_for(id, opts.merge(:repo_id => self.active_repository))
      end

    end
  end
end
