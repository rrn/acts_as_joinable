module FeedableExtensions
  def self.add
    Feed.class_eval do
      # Filter feeds about public joinables that you haven't joined, unless the feed is actually about you
      scope :without_unjoined, lambda {|joinable_type, user| 
        where("feeds.scoping_object_type IS NULL OR
               feeds.scoping_object_type != '#{joinable_type}' OR
               (feeds.feedable_type = 'User' AND feeds.feedable_id = #{user.id}) OR
               EXISTS (SELECT * FROM memberships WHERE memberships.joinable_type = '#{joinable_type}' AND memberships.joinable_id = feeds.scoping_object_id AND memberships.user_id = ?)", user.id)
      }

      acts_as_joinable_component :parent => 'permission_inheritance_target', :polymorphic => true, :view_permission => lambda {|feed| :find if feed.feedable.acts_like?(:joinable) }
      
      # The scoping_object becomes the parent if the feed is delegated to a non-permissable or the feedable is deleted
      # eg. a user (non-permissible) leaves a project, the parent of the feed is the project since a user isn't a permissable
      # eg. a writeboard is destroyed, the parent of the feed is now the project
      def permission_inheritance_target_type
        if feedable.acts_like?(:permissable)
          feedable_type
        else
          scoping_object_type
        end
      end
      
      def permission_inheritance_target_id
        if feedable.acts_like?(:permissable)
          feedable_id
        else
          scoping_object_id
        end
      end
    end
  end
end