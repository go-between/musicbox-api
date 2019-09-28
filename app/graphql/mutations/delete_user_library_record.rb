module Mutations
  class DeleteUserLibraryRecord < Mutations::BaseMutation
    argument :id, ID, required: true

    field :errors, [String], null: true

    def resolve(id:)
      record = UserLibraryRecord.find_by(id: id, user: context[:current_user])
      return { errors: ["Can't find song to delete"] } if record.blank?

      record.destroy!
      {
        errors: []
      }
    end
  end
end
