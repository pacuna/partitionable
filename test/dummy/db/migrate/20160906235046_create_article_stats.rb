class CreateArticleStats < ActiveRecord::Migration[5.0]
  def change
    create_table :article_stats do |t|
      t.string :token
      t.date :logdate
      t.string :site
      t.integer :pageviews
      t.integer :sessions

      t.timestamps
    end
  end
end
