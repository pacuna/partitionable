class CreateArticles < ActiveRecord::Migration[5.0]
  def change
    create_table :articles do |t|
      t.string :author
      t.boolean :published
      t.string :title
      t.string :slug
      t.text :body
      t.date :logdate

      t.timestamps
    end
  end
end
