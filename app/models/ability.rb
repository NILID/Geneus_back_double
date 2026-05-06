# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    # --- Все авторизованные пользователи ---
    can :read, Person
    can :read, GalleryPhoto
    can :read, Idea
    can :create, Idea
    can :read, PersonFact

    can :create, Comment do |comment|
      next false unless user

      case comment.commentable_type
      when 'Idea'
        true
      when 'GalleryPhoto'
        true
      else
        false
      end
    end

    # --- Модератор и администратор: редактирование данных (кроме аудита у модератора) ---
    if user.moderator? || user.admin?
      can :invite, User
      can :update, Person
      can :update_tree, Person
      can :create, GalleryPhoto
      can :update, GalleryPhoto
      can :destroy, GalleryPhoto
      can :create, PersonFact
    end

    # --- Только администратор ---
    return unless user.admin?

    can :read, Audited::Audit
    can :read, User
    can :update_role, User
  end
end
